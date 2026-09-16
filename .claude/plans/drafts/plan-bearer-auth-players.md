# Plan: Player Auth — Cookie + Bearer

**Created:** 2026-09-16
**Status:** Draft
**Branch:** `player-auth`

## Problem

Player tokens are exposed in URLs:

```
GET /api/v1/players/abc123def/manifest
GET /play/players/abc123def
```

The token is an authentication credential. Exposing it in URLs means
it appears in server access logs, browser history, Referrer headers,
and network proxy logs. Public IDs should be used for identification;
tokens strictly for authentication.

## Design: Dual auth (cookie + bearer)

Support two auth mechanisms — `authenticate_player!` checks bearer
first, falls back to cookie:

```ruby
def authenticate_player!
  token = request.headers["Authorization"]&.delete_prefix("Bearer ") ||
          cookies.signed[:player_token]
  @player = Player.find_by(token: token)
  render_error "Invalid player token", status: :unauthorized unless @player
end
```

| Auth method | When it's used | How token is stored |
|-------------|---------------|---------------------|
| **Cookie** | Browser players — HTML page loads and JS fetch calls | HttpOnly signed cookie set at registration |
| **Bearer** | Future native apps (Fire TV, Android TV), external API consumers | Stored by the app, sent in Authorization header |

Browser-based players use the cookie for everything — Play page
loads, API fetch calls (via `credentials: "include"`), all without
the token appearing in a URL. Bearer is available for non-browser
clients that can't use cookies.

## URL Changes

### API endpoints

```
# Before
GET  /api/v1/players/:token/manifest
POST /api/v1/players/:token/heartbeat
POST /api/v1/players/:token/pairing_code
GET  /api/v1/players/:token

# After
GET  /api/v1/player/manifest
POST /api/v1/player/heartbeat
POST /api/v1/player/pairing_code
GET  /api/v1/player
```

Singular `player` resource — the player is identified by the auth
credential (cookie or bearer), no ID in the URL.

### Play endpoints

```
# Before
GET /play/players/:token

# After
GET /play/players/:pid
```

`public_id` in the URL for identification. The cookie authenticates.
The landing page redirects to `/players/:pid` using the stored
`public_id` from localStorage (not the token).

### Registration

```
POST /api/v1/players  (unauthenticated)
```

Response:
```json
{
  "data": {
    "pairing_code": "A7B3K2",
    "token": "abc123def...",
    "public_id": "a1b2c3d4-...",
    "expires_in": 600
  }
}
```

The controller also sets the cookie:
```ruby
cookies.signed[:player_token] = {
  value: player.token,
  httponly: true,
  secure: Rails.env.production?,
  same_site: :lax,
  domain: :all
}
```

`domain: :all` makes the cookie available across subdomains (play,
api) — same as the session cookie.

The JS client stores `public_id` in localStorage for the redirect
URL and `token` for bearer auth (native app fallback). Browser
players primarily use the cookie.

### ActionCable

Currently passes token in subscription params. With cookies
available across subdomains, ActionCable can authenticate from the
cookie via the connection class:

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :player

    def connect
      self.player = find_player
    end

    private

    def find_player
      token = cookies.signed[:player_token]
      Player.find_by(token: token) || reject_unauthorized_connection
    end
  end
end
```

The JS subscription no longer needs to pass the token:
```js
consumer.subscriptions.create({ channel: "ScreenChannel" })
```

The channel resolves the player from the connection identity.

## Changes Summary

| Component | Before | After |
|-----------|--------|-------|
| API auth | Token in URL path | Bearer header or cookie |
| Play auth | Token in URL path | Cookie + public_id in URL |
| API routes | `/v1/players/:token/*` | `/v1/player/*` (singular) |
| Play routes | `/players/:token` | `/players/:pid` |
| Registration | Returns token | Returns token + public_id, sets cookie |
| ActionCable | Token in subscription params | Cookie via connection class |
| localStorage | Stores token | Stores public_id (and token for bearer fallback) |
| JS fetch calls | Token in URL | `credentials: "include"` (cookie) |

## Execution

### Step 1 — Dual auth in base controllers (TDD)
- **RED:** Spec asserting bearer auth and cookie auth both work
- **GREEN:** Update `authenticate_player!` in Api::BaseController and Play::BaseController

### Step 2 — Registration sets cookie (TDD)
- **RED:** Spec asserting registration response includes public_id and sets signed cookie
- **GREEN:** Update PlayersController#create

### Step 3 — Singular API routes
- Update routes: `resource :player` (singular, authenticated)
- Update API controller paths
- Update specs

### Step 4 — Play routes use public_id
- Change `param: :token` to `param: :id` (resolves via `find_by_param!`)
- Update Play::BaseController to auth from cookie
- Update landing page JS to redirect with public_id

### Step 5 — ActionCable connection auth
- Update `ApplicationCable::Connection` to auth from cookie
- Update `ScreenChannel` to use `connection.player`
- Remove token from JS subscription params

### Step 6 — JS client updates
- `device_playback_controller.js`: remove token from fetch URLs,
  use `credentials: "include"` for cookie auth
- Store public_id in localStorage instead of token for redirects
- Keep token in localStorage as bearer fallback

### Step 7 — Update specs, seeds, docs
- Update all API and Play specs
- Update player API docs, architecture docs
- `make lint`, `make test`
- Push, create PR

## Out of Scope

- Token rotation / revocation (separate concern)
- Provisioned app auth flow (will use bearer when native apps exist)
