# Plan: Play as Self-Contained App

**Created:** 2026-09-17
**Status:** Draft
**Branch:** `play-self-contained` (branch off `player-sessions`)

## Problem

The browser player flow currently spans two subdomains:

1. Play subdomain renders HTML and sets cookies
2. API subdomain handles registration, heartbeats, manifest, pairing codes

This creates a cross-origin dance: the JS on `play.replaytv.co`
fetches from `api.replaytv.co`, gets a session_id back, then POSTs
to `play.replaytv.co/player/session` to set the cookie. CORS config,
`SameSite` cookie issues, and `skip_forgery_protection` are all
consequences of this split.

Browser players don't need the API subdomain. They can do everything
on Play — register, pair, heartbeat, get manifests — all same-origin.
The API subdomain stays for native apps (Fire TV app, Android TV app)
that use bearer tokens and don't have cookies.

## Design

### Play — browser players (same-origin, cookie auth)

```
play.replaytv.co/
  resource :player, only: [:new, :show, :create] do
    resource :session, only: :create      # set cookie (kept for re-auth after pairing)
    resource :heartbeat, only: :create
    resource :manifest, only: :show
    resource :pairing_code, only: :create
  end
```

All same-origin. Cookie set directly on registration response. No
CORS needed. No cross-origin fetch. No two-step session dance.

### API — native apps (cross-origin, bearer auth)

```
api.replaytv.co/v1/
  resources :players, only: :create       # register (returns token for bearer)
  resource :player, only: :show do        # bearer auth
    resource :heartbeat, only: :create
    resource :manifest, only: :show
    resource :pairing_code, only: :create
  end
```

Same endpoints, bearer auth instead of cookies. For future native
apps that can't use cookies.

### Shared logic — service objects

The controllers are thin wrappers. The actual logic lives in services:

| Service | What it does |
|---------|-------------|
| `RegisterPlayer` | Creates Player + PlayerSession, parses device info |
| `PairPlayerToScreen` | Already exists — pairs, revokes old sessions, creates new |
| `RecordHeartbeat` | Updates session activity + player device info |
| `ParseDeviceInfo` | Already exists (rename to `UpdateDeviceInfo` per todo) |

Play controllers call services and set cookies. API controllers call
the same services and return JSON for bearer auth.

### Play::PlayersController becomes self-contained

```ruby
module Play
  class PlayersController < Play::BaseController
    before_action :authenticate_player!, only: %i[show]

    # GET /player/new — pairing screen
    def new; end

    # GET /player — playback content
    def show
      # ... same as today
    end

    # POST /player — register a new device + set cookie
    def create
      result = RegisterPlayer.new(
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        params: player_params
      ).call

      cookies.signed[:player_session_id] = {
        value: result.session.id,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        expires: 1.year.from_now,
        domain: :all
      }

      render json: {
        pairing_code: result.player.pairing_code,
        public_id: result.player.public_id,
        expires_at: result.player.pairing_code_expires_at
      }, status: :created
    end
  end
end
```

### JS simplification

Registration becomes same-origin — no CORS, no session dance:

```js
// Before (cross-origin + session dance)
const res = await fetch(`${apiHost}/v1/players`, { credentials: "include", ... })
const { data } = await res.json()
await fetch("/player/session", { body: JSON.stringify({ session_id: data.session_id }) })

// After (same-origin, cookie set in response)
const res = await fetch("/player", { method: "POST", ... })
const { data } = await res.json()
// Cookie already set — done
```

Heartbeat and manifest become same-origin too:

```js
// Before
fetch(`${apiHost}/v1/player/heartbeat`, { credentials: "include", ... })
fetch(`${apiHost}/v1/player/manifest`, { credentials: "include", ... })

// After
fetch("/player/heartbeat", { method: "POST", ... })
fetch("/player/manifest")
```

No `apiHost` Stimulus value needed. No `credentials: "include"`. No
CORS. Everything is relative.

### What this removes

- `apiHost` Stimulus values on pairing and playback controllers
- `data-device-pairing-api-host-value` from templates
- CORS config for `/v1/player*` endpoints (API still needs CORS for
  native apps, but Play doesn't)
- The `/player/session` endpoint (cookie set directly on registration)
- Cross-origin cookie issues entirely

## Todo items (from PR review, addressed here or in separate plan)

| Item | Where | Action |
|------|-------|--------|
| Move IP/UA to session | heartbeat | IP + UA tracked on session, device fields on player |
| Rename ParseDeviceInfo → UpdateDeviceInfo | service | Rename |
| Return expires_at instead of expires_in | pairing code response | Let UI calculate countdown |
| /player as default landing (remove landing.html.erb) | routes | Root points to show, auth redirects to new |

## Execution

### Step 1 — RegisterPlayer service (TDD)
- **RED:** Service spec — creates Player + PlayerSession, returns result
- **GREEN:** Extract from Api::V1::PlayersController#create

### Step 2 — Play registration (TDD)
- **RED:** Play spec for `POST /player` — creates player, sets cookie, returns JSON
- **GREEN:** Add `create` to Play::PlayersController, set cookie directly

### Step 3 — Play heartbeat (TDD)
- **RED:** Play spec for `POST /player/heartbeat`
- **GREEN:** `Play::HeartbeatsController` — same logic as API heartbeat

### Step 4 — Play manifest
- Move manifest rendering to Play
- `GET /player/manifest` — same Jbuilder templates

### Step 5 — Play pairing code
- `POST /player/pairing_code`
- Same logic as API pairing code controller

### Step 6 — Simplify JS client
- Remove `apiHost` values from Stimulus controllers
- All fetch calls become relative URLs
- Remove `credentials: "include"` (same-origin doesn't need it)
- Remove session dance from pairing JS

### Step 7 — Remove /player/session endpoint
- No longer needed — cookie set on registration
- Keep it for re-auth on pairing? Or set cookie in the pairing
  broadcast handler (PairPlayerToScreen creates new session,
  Play controller can set cookie when showing content)

### Step 8 — Root points to /player
- `root "players#show"` with auth redirect to `new`
- Remove landing.html.erb

### Step 9 — Address todo items
- Move IP/UA to PlayerSession on heartbeat
- Rename ParseDeviceInfo → UpdateDeviceInfo
- Return expires_at instead of expires_in

### Step 10 — Update Play controller comments
- Remove stale comments

### Step 11 — Clean up CORS
- Remove Play-related CORS rules (no longer cross-origin)
- Keep API CORS for native apps

### Step 12 — Ship
- `make lint`, `make test`
- Push, create PR (merges to player-sessions, then to player-auth, then to main)

## Out of Scope

- Native app bearer auth flow (API stays as-is for that)
- Removing the API player endpoints (still needed for native apps)
- ActionCable changes (already uses cookie auth)
