# Player API

The player API spans two subdomains: `play` (HTML for screen rendering) and `api` (JSON for device communication).

## API subdomain (JSON)

Base URL: `api.replay.com`

### Register device

```
POST /players
```

Creates a new player with a pairing code. No authentication required.

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

Sent every 30 seconds by the player to report it's alive. Updates `last_heartbeat_at`, `ip_address`, and `user_agent`.

**Response** `200 OK`:
```json
{
  "ok": true
}
```

A player is considered online when `last_heartbeat_at > 2.minutes.ago`.

### Record impression

```
POST /players/:token/impressions
```

Records that an ad was displayed on screen.

**Request body**:
```json
{
  "ad_id": 42,
  "playlist_id": 3,
  "position": 2,
  "duration": 10
}
```

The controller resolves `screen_id`, `site_id`, and `account_id` from the player's active `ScreenPlayer` assignment.

**Response** `201 Created`

## Play subdomain (HTML)

Base URL: `play.replay.com`

### Pairing screen

```
GET /players/new
```

Renders the pairing UI. The `device_pairing_controller.js` Stimulus controller handles registration and code display.

### Playback

```
GET /players/:token
```

Renders the slideshow for the paired screen. Three possible states:

| State | Condition | Renders |
|-------|-----------|---------|
| Slideshow | Paired + has playlist | Full-screen ad rotation with crossfade |
| Idle | Paired + no playlist | "No playlist assigned" |
| Unpaired | Not paired | Pairing code screen |

The `device_playback_controller.js` handles:
- Heartbeat every 30 seconds
- Impression reporting per slide
- ActionCable subscription for playlist change notifications

## Scan endpoint (any subdomain)

```
GET /s/:token?a=<ad_id>&s=<screen_id>&p=<playlist_id>
```

Records a QR scan and redirects to the destination. See [scan-api.md](scan-api.md).

## Authentication

API endpoints authenticate via the player token in the URL path (`/players/:token/...`). No headers, no cookies. The token is generated at registration and stored in the player's `localStorage`.

Registration (`POST /players`) requires no authentication — any device can register.

## Rate limiting

| Endpoint | Limit |
|----------|-------|
| `POST /players` | 5 per IP per hour |
| `GET /s/:token` | 60 per IP per minute |
