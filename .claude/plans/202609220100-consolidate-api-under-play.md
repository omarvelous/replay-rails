# Plan: Consolidate API Under Play Subdomain

**Created:** 2026-09-22
**Status:** Draft
**Branch:** TBD

## Problem

The player API and Play subdomain are separate, causing:
- Duplicate controllers (heartbeat, manifest, pairing code, session)
- Cross-origin cookie workarounds (the entire /player/session endpoint)
- CORS configuration for player endpoints
- Two auth paths for the same device communication

Browser players already do everything on Play. The API subdomain
exists for future native apps, but native apps can use
`play.replaytv.co/api/v1/` just as easily.

## Design

Move API routes under the Play subdomain. Same origin = cookies
just work. Remove all duplicate Play JSON controllers.

### Before

```
play.replaytv.co/
  GET  /player/new          → HTML pairing
  GET  /player              → HTML playback
  POST /player              → JSON registration + set cookie
  POST /player/session      → JSON set cookie (cross-origin workaround)
  POST /player/heartbeat    → JSON heartbeat (duplicate)
  GET  /player/manifest     → JSON manifest (duplicate)
  POST /player/pairing_code → JSON pairing code (duplicate)

api.replaytv.co/v1/
  POST /players             → JSON registration
  GET  /player              → JSON status
  POST /player/heartbeat    → JSON heartbeat
  GET  /player/manifest     → JSON manifest
  POST /player/pairing_code → JSON pairing code
```

### After

```
play.replaytv.co/
  GET  /player/new          → HTML pairing
  GET  /player              → HTML playback

  POST /api/v1/players             → JSON registration + set cookie
  GET  /api/v1/player              → JSON status
  POST /api/v1/player/heartbeat    → JSON heartbeat
  GET  /api/v1/player/manifest     → JSON manifest
  POST /api/v1/player/pairing_code → JSON pairing code
```

5 JSON endpoints (API), 2 HTML views (Play). Zero duplication.

### Routes

API is scoped under `Play` to leave room for `App::Api` later.

```ruby
constraints subdomain: "play" do
  scope module: "play" do
    root "players#show", as: :play_root
    resource :player, only: %i[new show]

    namespace :api do
      namespace :v1 do
        resources :players, only: :create
        resource :player, only: :show do
          resource :heartbeat, only: :create
          resource :manifest, only: :show
          resource :pairing_code, only: :create
        end
      end
    end
  end
end
```

### Controller namespace

Controllers move from `Api::V1::*` to `Play::Api::V1::*`:

```
app/controllers/play/api/v1/
  base_controller.rb
  players_controller.rb
  players/
    heartbeats_controller.rb
    manifests_controller.rb
    pairing_codes_controller.rb
```

`Play::Api::V1::BaseController` inherits from `Play::BaseController`
(gets cookie auth, skip_forgery_protection) and adds JSON-specific
concerns (render_data, render_error, rate limits).

### Registration sets cookie

`Play::Api::V1::PlayersController#create` sets the cookie directly —
same origin, no cross-origin issues:

```ruby
def create
  result = RegisterPlayer.new(...).call

  cookies.signed[:player_session_id] = {
    value: result.session.id,
    httponly: true,
    secure: Rails.env.production?,
    same_site: :lax,
    expires: 1.year.from_now
  }

  render_data(...)
end
```

No `domain: :all` needed — same origin.

### JS simplified

All fetch calls use `/api/v1/player/*`:

```js
// Registration
fetch("/api/v1/players", { method: "POST", ... })
// Cookie set in response — done

// Heartbeat
fetch("/api/v1/player/heartbeat", { method: "POST", ... })

// Manifest
fetch("/api/v1/player/manifest")

// Pairing code
fetch("/api/v1/player/pairing_code", { method: "POST", ... })

// Status check
fetch("/api/v1/player", { headers: { "Accept": "application/json" } })
```

No `credentials: "include"`. No session dance. No `/player/session`
endpoint.

### What gets deleted

- `app/controllers/play/heartbeats_controller.rb`
- `app/controllers/play/manifests_controller.rb`
- `app/controllers/play/pairing_codes_controller.rb`
- `app/controllers/play/sessions_controller.rb`
- `spec/requests/play/heartbeats_spec.rb`
- `spec/requests/play/manifests_spec.rb`
- `spec/requests/play/pairing_codes_spec.rb`
- Play session specs in `spec/requests/play/players_spec.rb`
- CORS config for player endpoints
- `Play::PlayersController#create` (registration moves to API)

### What stays

- `Play::BaseController` — layout, auth redirect, skip_forgery_protection
- `Play::PlayersController` — `new` and `show` only (HTML)
- `Play::Api::V1::BaseController` — JSON error handling, rate limits
- `Play::Api::V1::*` controllers — all JSON endpoints

### What gets moved

- `app/controllers/api/` → `app/controllers/play/api/`
- `Api::V1::*` → `Play::Api::V1::*`
- `spec/requests/api/` → `spec/requests/play/api/`

## Execution

### Step 1 — Move controllers to Play::Api namespace
- Create `app/controllers/play/api/v1/` directory
- Move + rename all API controllers to `Play::Api::V1::*`
- `Play::Api::V1::BaseController < Play::BaseController` with
  JSON-specific concerns (render_data, render_error, rate limits)

### Step 2 — Update routes
- Nest `namespace :api` inside Play's `scope module: "play"` block
- Remove API subdomain constraint block (dropped in plan 2)

### Step 3 — API registration sets cookie
- Add cookie setting to `Play::Api::V1::PlayersController#create`
- Same-origin, no `domain: :all` needed

### Step 4 — Update JS to use /api/v1/* endpoints
- `device_pairing_controller.js` — all fetches to `/api/v1/*`
- `device_playback_controller.js` — heartbeat + manifest to `/api/v1/*`
- Remove session dance from pairing flow

### Step 5 — Delete duplicate Play controllers + specs
- Remove Play::PlayersController#create (registration in API)
- Remove Play heartbeats, manifests, pairing_codes, sessions controllers
- Remove their specs
- Play controller only has `new` and `show`

### Step 6 — Clean up CORS
- Remove player endpoint CORS rules (same origin now)

### Step 7 — Update specs
- Move API specs to `spec/requests/play/api/`
- Update host! and paths
- Remove session dance specs

### Step 8 — Ship
- `make lint`, `make test`
- Update docs
- Push, create PR
