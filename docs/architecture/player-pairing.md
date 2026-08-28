# Player Pairing

Players are physical devices (typically a Raspberry Pi or similar) connected to a TV screen. The pairing flow connects a player to a screen so it can display playlists.

## Three models

| Model | Purpose |
|-------|---------|
| `Screen` | Logical representation of a TV at a site |
| `Player` | Physical device with a token and heartbeat |
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
9. Slideshow begins playing
```

### Step details

**Device registration** (`POST api.replay.com/players`):
- Creates a `Player` with a random 32-byte `token` and a 6-character alphanumeric `pairing_code`
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

Updates `last_heartbeat_at`, `ip_address`, and `user_agent` on the Player record.

**Online detection**: `Player#online?` returns true when:
- Player is paired (has an active ScreenPlayer)
- `last_heartbeat_at` is within the last 2 minutes

The admin dashboard shows online/offline player counts based on this.

## Playlist changes

When a `ScreenPlaylist` is created, updated, or destroyed, an `after_commit` callback broadcasts to `screen_#{screen_id}`:

```ruby
after_commit -> { broadcast_playlist_changed }, on: [:create, :update, :destroy]
```

The player's `device_playback_controller.js` subscribes to `ScreenChannel` and reloads the page when it receives `{ event: "playlist_changed" }`. This gives near-instant content updates.

## Unpairing

`ScreenPlayer#unpair!` sets `active: false` and stamps `unpaired_at`. The player record persists — it can be re-paired to a different screen.

## Playback

`GET play.replay.com/players/:token` renders one of three states:

| State | Condition | What renders |
|-------|-----------|-------------|
| Slideshow | Paired + has playlist | Full ad slideshow with crossfade transitions |
| Idle | Paired + no playlist | "No playlist assigned" screen |
| Unpaired | Not paired | "Enter pairing code" screen |

The slideshow renders each `PlaylistAd` as a full-screen slide with the ad's layout partial. Transitions use opacity crossfade controlled by `slideshow_controller.js`.

## Impressions

During playback, the player reports impressions:

```
POST api.replay.com/players/:token/impressions
  { ad_id, playlist_id, position, duration }
```

The controller resolves the player's screen, site, and account from the active `ScreenPlayer` assignment and creates an `Impression` record with all 6 foreign keys.
