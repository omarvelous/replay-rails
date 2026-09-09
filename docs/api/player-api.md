# Player API

The player API spans two subdomains: `play` (HTML for screen rendering) and `api` (JSON for device communication).

## API subdomain (JSON)

Base URL: `api.replaytv.co`

### Register device

```
POST /players
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

Provisioned devices (Fire TV, dedicated hardware) send `app_version`. Browser players omit it. The presence of `app_version` distinguishes provisioned from browser players.

**Response** `201 Created`:
```json
{
  "pairing_code": "A7B3K2",
  "token": "abc123...def456",
  "expires_in": 600
}
```

The pairing code expires after 10 minutes. The token is a permanent 32-byte identifier used for all subsequent requests.

### Player status

```
GET /players/:token
```

Returns the player's current state. Auth: token in URL.

**Response** `200 OK`:
```json
{
  "paired": true,
  "screen_id": 7
}
```

### Heartbeat

```
POST /players/:token/heartbeat
```

Sent every 30 seconds by the player to report it's alive. Updates `last_heartbeat_at`, `ip_address`, and `user_agent`. If the user agent changes (OS or browser update), device fields are re-parsed.

**Request body** (optional — updates resolution):
```json
{
  "screen_width": 1920,
  "screen_height": 1080
}
```

**Response** `200 OK`:
```json
{
  "ok": true
}
```

A player is considered online when `last_heartbeat_at > 2.minutes.ago`.

**Response** `410 Gone` — player is no longer paired. The player should redirect to the pairing screen.

### Pairing code refresh

```
POST /players/:token/pairing_code
```

Generates a new 6-character pairing code. Used when the current code expires (10 minutes).

**Response** `200 OK`:
```json
{
  "pairing_code": "X9M4P1",
  "expires_in": 600
}
```

## Play subdomain (HTML)

Base URL: `play.replaytv.co`

### Pairing screen

```
GET /players/new
```

Renders the pairing UI. The `device_pairing_controller.js` Stimulus controller handles registration (with device info), code display, and WebSocket subscription for pairing events.

### Playback

```
GET /players/:token
```

Renders content for the paired screen. Four possible states:

| State | Condition | Renders |
|-------|-----------|---------|
| Slideshow | Paired + playlist content | Full-screen ad rotation with crossfade |
| Experience | Paired + experience content | Interactive kiosk with photos, details, agent, QR |
| Idle | Paired + no content | "No content assigned" |
| Unpaired | Not paired | Pairing code screen |

The `device_playback_controller.js` handles:
- Heartbeat every 30 seconds (with screen resolution)
- Analytics event tracking via `Analytics.create()` (content.impressed, device.connected)
- ActionCable subscription for content change notifications

The `experience_controller.js` additionally handles:
- Touch detection and idle/attract mode
- Kiosk session tracking via `ahoy.reset()` on interaction start
- Interaction events (started, ended, navigated, opened, closed)

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

Player events are tracked via Ahoy (ahoy.js client-side). Impressions are no longer sent to a dedicated API endpoint — they're tracked as `content.impressed` Ahoy events via `Analytics.create()` in the player JS. See `docs/dev/event-catalog.md`.

## Authentication

API endpoints authenticate via the player token in the URL path (`/players/:token/...`). No headers, no cookies for auth. Ahoy cookies are shared across subdomains for visit tracking (`credentials: "include"` on fetch calls).

Registration (`POST /players`) requires no authentication — any device can register.

## Rate limiting

| Endpoint | Limit |
|----------|-------|
| `POST /players` | 5 per IP per hour |
| `GET /s/:token` | 60 per IP per minute |
