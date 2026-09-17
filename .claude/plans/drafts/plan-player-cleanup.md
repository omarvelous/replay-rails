# Plan: Player Cleanup

**Created:** 2026-09-17
**Status:** Draft
**Branch:** TBD (after play-self-contained)

## Items

### 1. Move IP/UA to PlayerSession on heartbeat

Device-level fields (`screen_width`, `screen_height`, `device_type`,
`device_model`, etc.) stay on Player. Per-session fields (`ip_address`,
`user_agent`) move to PlayerSession — they can change between sessions.

**Files:** `app/controllers/api/v1/players/heartbeats_controller.rb`,
`app/models/player_session.rb`, migration to add `ip_address`/`user_agent`
to `player_sessions` (already has them from creation, but heartbeat
should update the session not the player).

### 2. Rename ParseDeviceInfo → UpdateDeviceInfo

The service parses the user agent AND writes to the database. The name
`ParseDeviceInfo` implies read-only. Rename to `UpdateDeviceInfo` to
match what it actually does.

**Files:** `app/services/parse_device_info.rb` → `app/services/update_device_info.rb`,
all references in controllers and specs.

### 3. Return expires_at instead of expires_in for pairing codes

Currently the API returns `expires_in: 600` (seconds from now). The JS
calculates the countdown from this, but there's clock drift between the
server response time and when the JS processes it. Return `expires_at`
(ISO 8601 timestamp) and let the JS calculate the remaining time.

**Files:** `app/controllers/api/v1/players/pairing_codes_controller.rb`,
`app/controllers/api/v1/players_controller.rb` (registration response),
`app/javascript/controllers/device_pairing_controller.js`.

### 4. /player as default Play landing

The landing page (`landing.html.erb`) just redirects to `/player` via JS.
Since the auth concern redirects unauthenticated requests to `/player/new`,
the Play root can point directly to `players#show`. Remove the landing
action and template.

**Files:** `config/routes.rb`, `app/controllers/play/players_controller.rb`,
`app/views/play/players/landing.html.erb` (delete).
