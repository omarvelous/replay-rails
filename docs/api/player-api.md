# Player API

Players are browser-based devices that render content on screens. Browser players communicate entirely through the `play` subdomain using cookie-based sessions. A native app API also exists for future use.

## Play subdomain (browser players)

Base URL: `play.replaytv.co`

Browser players are self-contained on the play subdomain. Auth is a signed cookie (`player_session_id`) set after pairing. No tokens in URLs.

### Register device

```
POST /player
```

Creates a new player with a pairing code. No authentication required. The server parses the user agent to populate device fields (model, manufacturer, OS, browser, device type).

**Request body** (optional — enriches device info):
```json
{
  "screen_width": 1920,
  "screen_height": 1080,
  "touch_capable": false,
  "app_version": "1.0.0"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `screen_width` | integer | Device screen width in pixels |
| `screen_height` | integer | Device screen height in pixels |
| `touch_capable` | boolean | Whether the device has touch input |
| `app_version` | string | Version of the RePlay app (null for browser players) |

The presence of `app_version` distinguishes provisioned devices (Fire TV, dedicated hardware) from plain browser players.

**Response** `201 Created`:
```json
{
  "pairing_code": "A7B3K2",
  "expires_in": 600
}
```

The pairing code expires after 10 minutes. The `PlayerSession` cookie is set in the response.

### Set session after pairing

```
POST /player/session
```

Called by the pairing page after `PairingChannel` broadcasts `{ paired: true }`. Sets the `player_session_id` signed cookie and redirects to `/player`.

### Pairing screen

```
GET /player/new
```

Renders the pairing UI. The `device_pairing_controller.js` Stimulus controller handles registration (with device info), code display, and WebSocket subscription for pairing events.

The root (`play.replaytv.co/`) redirects here automatically when no session is present.

### Playback

```
GET /player
```

Renders content for the paired screen. Four possible states:

| State | Condition | Renders |
|-------|-----------|---------|
| Slideshow | Paired + playlist content | Full-screen ad rotation with crossfade |
| Experience | Paired + experience content | Interactive kiosk with photos, details, agent, QR |
| Idle | Paired + no content | "No content assigned" |
| Unpaired | No session | Redirect to `/player/new` |

The `device_playback_controller.js` handles:
- Heartbeat every 30 seconds (with screen resolution)
- Analytics event tracking via `Analytics.create()` (content.impressed, device.connected)
- ActionCable subscription for content change notifications

The `experience_controller.js` additionally handles:
- Touch detection and idle/attract mode
- Kiosk session tracking via `ahoy.reset()` on interaction start
- Interaction events (started, ended, navigated, opened, closed)

### Content manifest

```
GET /player/manifest
```

Returns a JSON dependency tree of everything the player renders. The player polls every 30 seconds with `If-None-Match` to detect content changes.

**Response** `200 OK` (content available):
```json
{
  "deploy": "a3f8c2",
  "screen_content": { "id": 1, "updated_at": 1725840000 },
  "contentable": {
    "type": "Playlist",
    "id": 5,
    "playlist_ads": [
      {
        "id": 10,
        "ad": { "id": 20, "updated_at": 1725837000, "adable": { "type": "Ads::ListingAd", "listing": { ... } } }
      }
    ]
  }
}
```

**Response** `304 Not Modified` — ETag matches, nothing changed.

**Response** `200 OK` (no content):
```json
{ "content": null }
```

The manifest includes `updated_at` for every model and attachment arrays from `active_storage_attachments`. Any change — model update, photo upload, deploy — produces a different JSON body and therefore a different ETag.

Jbuilder templates resolve partials dynamically by contentable and adable type. See `app/views/play/players/manifests/`.

### Heartbeat

```
POST /player/heartbeat
```

Sent every 30 seconds to report the player is alive. Updates `last_heartbeat_at`, `ip_address`, and `user_agent`. If the user agent changes (OS or browser update), device fields are re-parsed.

**Request body** (optional — updates resolution):
```json
{
  "screen_width": 1920,
  "screen_height": 1080
}
```

**Response** `200 OK`:
```json
{ "ok": true }
```

A player is considered online when `last_heartbeat_at > 2.minutes.ago`.

**Response** `410 Gone` — player session is no longer valid. The player should redirect to `/player/new`.

### Pairing code refresh

```
POST /player/pairing_code
```

Generates a new 6-character pairing code. Used when the current code expires (10 minutes).

**Response** `200 OK`:
```json
{
  "pairing_code": "X9M4P1",
  "expires_in": 600
}
```

## API subdomain (native apps)

Base URL: `api.replaytv.co`

Reserved for future native app clients. Uses the same session-based cookie auth as the play subdomain. Endpoints mirror the play routes under `/v1/player/`.

## Device Detection

On registration and heartbeat, the server parses the user agent via the `device_detector` gem to populate:

| Field | Example |
|-------|---------|
| `device_type` | `fire_tv`, `browser_desktop`, `browser_mobile`, `provisioned`, `unknown` |
| `device_model` | "Fire TV Stick 4K", "iPad Pro" |
| `device_manufacturer` | "Amazon", "Apple" |
| `os_name` | "Fire OS", "iPadOS", "Chrome OS" |
| `os_version` | "7.6.3.3", "17.0" |
| `browser_name` | "Silk", "Safari", "Chrome" |
| `browser_version` | "120.0.0" |

Device type is an enum with fallback: `fire_tv`, `android_tv`, `raspberry_pi`, `browser_desktop`, `browser_mobile`, `browser_tablet`, `browser_tv`, `provisioned`, `unknown`.

## Scan endpoint (any subdomain)

```
GET /s/:token?a=<ad_id>&s=<screen_id>&sc=<screen_content_id>
```

Records a QR scan and redirects to the destination. The `sc` param captures the screen content assignment active at scan time. See [scan-api.md](scan-api.md).

## Analytics

Player events are tracked via Ahoy (ahoy.js client-side). Impressions are tracked as `content.impressed` Ahoy events via `Analytics.create()` in the player JS. See `docs/dev/event-catalog.md`.

## Authentication

Browser players authenticate via the `player_session_id` signed cookie set after pairing. No tokens in URLs. Ahoy cookies are shared across subdomains for visit tracking.

Registration (`POST /player`) requires no authentication — any device can register.

## Rate limiting

| Endpoint | Limit |
|----------|-------|
| `POST /player` | 5 per IP per hour |
| `GET /s/:token` | 60 per IP per minute |
