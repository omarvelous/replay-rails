# Player Pairing

Players are browser-based devices (Fire TV, Raspberry Pi, iPad, any browser) connected to a TV screen. The pairing flow connects a player to a screen so it can display content.

## Three models

| Model | Purpose |
|-------|---------|
| `Screen` | Logical representation of a TV at a site |
| `Player` | Physical device with a token, heartbeat, and device metadata |
| `ScreenPlayer` | Join model with pairing history |

`ScreenPlayer` tracks active/historical assignments:
- `active: true` — currently paired
- `active: false` — previously paired (history preserved)
- `paired_by_id` — which user initiated the pairing
- `unpaired_at` — when it was disconnected

## Pairing flow

```
1. Device opens play.replay.com/players/new
2. JS POSTs to api.replay.com/players → gets pairing_code + token
3. Screen displays 6-character code (e.g., A7B3K2)
4. JS subscribes to PairingChannel on that code
5. Manager enters code in app → App::ScreenPlayersController#create
6. Screen#pair_player! creates ScreenPlayer, clears pairing_code
7. ActionCable broadcasts { paired: true } to PairingChannel
8. Device stores token in localStorage, redirects to /players/:token
9. Content playback begins
```

### Step details

**Device registration** (`POST api.replay.com/players`):
- Creates a `Player` with a random 32-byte `token` and a 6-character alphanumeric `pairing_code`
- Parses user agent via `device_detector` gem for device type, model, manufacturer, OS, browser
- Accepts client-reported info: `screen_width`, `screen_height`, `touch_capable`, `app_version`
- Pairing code expires after 10 minutes
- Returns `{ pairing_code, token, expires_in: 600 }`

**Pairing** (`Screen#pair_player!`):
- Deactivates any existing `ScreenPlayer` on both the screen and player (a player can only be on one screen, a screen can only have one player)
- Creates a new `ScreenPlayer(active: true, paired_by: current_user)`
- Clears the player's `pairing_code`

**ActionCable push**:
- `PairingChannel` streams from `pairing_#{code}`
- On pairing, broadcasts `{ paired: true }`
- Client receives the event and navigates to the playback URL

## Heartbeat

Once paired, the player sends a heartbeat every 30 seconds:

```
POST api.replay.com/players/:token/heartbeat
```

Updates `last_heartbeat_at`, `ip_address`, and `user_agent`. Re-parses user agent if changed. Accepts updated `screen_width`/`screen_height`.

**Online detection**: `Player#online?` returns true when:
- Player is paired (has an active ScreenPlayer)
- `last_heartbeat_at` is within the last 2 minutes

## Content sync

Players poll for content changes via the manifest endpoint:

```
GET api.replay.com/players/:token/manifest
```

The manifest is a Jbuilder JSON dependency tree of all models and attachments for the screen's active content. `Rack::ETag` auto-generates an ETag from the response body. Polling every 30 seconds returns `304` when unchanged, `200` when any dependency changed.

ActionCable `content_changed` events trigger an immediate manifest check (with 2s debounce) instead of waiting for the next poll cycle.

## Content changes

When a `ScreenContent` is created, updated, or destroyed, an `after_commit` callback broadcasts to `screen_#{screen_id}`:

```ruby
after_commit -> { broadcast_content_changed }, on: [:create, :update, :destroy]
```

The player's `device_playback_controller.js` subscribes to `ScreenChannel` and checks the manifest when it receives the event.

## Unpairing

`ScreenPlayer#unpair!` sets `active: false` and stamps `unpaired_at`. The player record persists — it can be re-paired to a different screen.

## Playback

`GET play.replay.com/players/:token` renders one of three states:

| State | Condition | What renders |
|-------|-----------|-------------|
| Slideshow | Paired + playlist content | Full ad slideshow with crossfade transitions |
| Experience | Paired + experience content | Interactive kiosk with photo gallery, agent card, QR handoff |
| Idle | Paired + no content | "No content assigned" screen |
| Unpaired | Not paired | "Enter pairing code" screen |

The player controller branches on `screen.content_type` to render the appropriate template.

## Analytics

During playback, the player JS fires governed events via the analytics wrapper:

- `content.impressed` — each time an ad slide is displayed (ad_pid, screen_pid, duration)
- `device.connected` — when the player starts playback
- `interaction.started` / `interaction.ended` — when a visitor touches the experience kiosk

Events are tracked via `ahoy.track()` with the Ahoy visit associated to the player's session.
