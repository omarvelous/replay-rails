# Plan: Player Sessions

**Created:** 2026-09-16
**Status:** Draft
**Branch:** `player-sessions`
**Depends on:** Player auth (cookie + bearer) — PR #70

## Problem

Player conflates device identity with authentication. The `token`
column on Player is both the device's permanent identifier and its
auth credential. This means:
- No way to revoke access without deleting the player record
- No session history (when was this device last authenticated, from where)
- Token rotation requires mutating the player record
- Admin can't see or manage active player sessions

## Design

Mirror the User/Session pattern from Rails 8 built-in auth exactly:

```
Player (device identity — persists forever)
  has_many :player_sessions

PlayerSession (auth credential — created on pairing, revokable)
  id (integer PK, stored in signed cookie)
  ip_address, user_agent, last_active_at, revoked_at
```

No `token` column on PlayerSession. The integer `id` in a signed
cookie is the credential — same pattern as `Session` for users.
`cookies.signed` makes the value tamper-proof. No one can forge
another session's ID because the signature would be invalid.

### PlayerSession model

```ruby
class PlayerSession < ApplicationRecord
  belongs_to :player

  scope :active, -> { where(revoked_at: nil) }

  def revoke!
    update!(revoked_at: Time.current)
  end
end
```

No token generation needed — the signed cookie ID is the secret.

### Migration

```ruby
create_table :player_sessions do |t|
  t.timestamps
  t.references :player, null: false, foreign_key: true
  t.string :ip_address
  t.string :user_agent
  t.datetime :last_active_at
  t.datetime :revoked_at
end
```

### Player model changes

- Remove `token` column (no longer needed)
- Remove `pairing_code`, `pairing_code_expires_at` (move to PlayerSession
  or keep on Player — see pairing section below)
- Keep device fields (device_type, device_model, screen_width, etc.)
- Add `has_many :player_sessions, dependent: :destroy`

### Auth flow — mirrors User auth exactly

**User auth:**
```ruby
cookies.signed[:session_id] = session.id
Session.find_by(id: cookies.signed[:session_id])
```

**Player auth:**
```ruby
cookies.signed[:player_session_id] = session.id
PlayerSession.active.find_by(id: cookies.signed[:player_session_id])
```

**authenticate_player!:**
```ruby
def authenticate_player!
  @player_session = PlayerSession.active.find_by(id: cookies.signed[:player_session_id])
  @player = @player_session&.player
  render_error "Invalid session", status: :unauthorized unless @player
end
```

No bearer token support for now — add it later if native apps need
it (a `token` column on PlayerSession, checked as fallback).

### Registration (`POST /v1/players`)

Creates Player + first PlayerSession. The session ID goes back in
the response so the Play JS can set the cookie via the same-origin
authenticate endpoint:

```ruby
def create
  player = Player.create!(...)
  session = player.player_sessions.create!(
    ip_address: request.remote_ip,
    user_agent: request.user_agent
  )

  render_data({
    public_id: player.public_id,
    pairing_code: player.pairing_code,
    session_id: session.id,
    expires_in: 600
  }, status: :created)
end
```

Note: `session_id` is safe to return in the API response because
it's only useful inside a signed cookie — the integer alone can't
authenticate without the Rails secret key.

### Play authenticate (`POST /players/authenticate`)

Same-origin endpoint on Play subdomain. Accepts session_id, sets
the signed cookie:

```ruby
def authenticate
  session = PlayerSession.active.find_by(id: params[:session_id])
  if session
    cookies.signed[:player_session_id] = {
      value: session.id,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
      expires: 1.year.from_now,
      domain: :all
    }
    render json: { ok: true }
  else
    render json: { error: "invalid session" }, status: :unauthorized
  end
end
```

### Heartbeat

Updates `player_session.last_active_at` + player device info:

```ruby
def create
  @player_session.update!(last_active_at: Time.current)
  @player.update!(
    ip_address: request.remote_ip,
    user_agent: request.user_agent,
    screen_width: params[:screen_width] || @player.screen_width,
    screen_height: params[:screen_height] || @player.screen_height
  )
end
```

### Pairing flow changes

`PairPlayerToScreen#call`:
1. Pairs player to screen (same as today)
2. Revokes all existing sessions: `player.player_sessions.active.each(&:revoke!)`
3. Creates a new session: `player.player_sessions.create!(ip_address:, user_agent:)`
4. Broadcasts `{ paired: true, session_id: new_session.id }` on PairingChannel

After pairing, the device JS:
1. Receives `{ paired: true, session_id }` on PairingChannel
2. Calls `POST /players/authenticate` with `session_id`
3. Cookie is set, redirects to `/players/:public_id`

The `session_id` in the broadcast is safe — it only works inside
a signed cookie. An eavesdropper who intercepts it can't use it
without the Rails secret key.

### Admin

Add PlayerSession to the admin panel:
- List sessions for a player (active + revoked)
- "Revoke" button to force re-auth
- Show last_active_at, ip_address, user_agent, created_at, revoked_at

### ActionCable

```ruby
def find_verified_player
  if session_id = cookies.signed[:player_session_id]
    session = PlayerSession.active.find_by(id: session_id)
    session&.player
  end
end
```

### What happens on revocation

1. Admin revokes session → `revoked_at` set
2. Next heartbeat: `authenticate_player!` finds no active session → 401
3. Playback JS handles 401 → redirect to pairing
4. ActionCable: reconnect attempt fails auth → connection dropped

## Execution

### Step 1 — PlayerSession model + migration (TDD)
- **RED:** Model spec — associations, active scope, revoke!
- **GREEN:** Migration, model, factory

### Step 2 — Update Player model
- Remove `token` from Player (migration to drop column)
- Add `has_many :player_sessions`
- Keep all device fields, pairing_code

### Step 3 — Update auth (TDD)
- **RED:** Auth spec using signed cookie with session ID
- **GREEN:** Update `authenticate_player!` in Api::BaseController and
  Play::BaseController to use PlayerSession
- Update `sign_in_player` test helper

### Step 4 — Update registration
- `POST /v1/players` creates Player + PlayerSession
- Returns session_id (not token)
- Update spec

### Step 5 — Update Play authenticate endpoint
- Cookie key: `:player_session_id`
- Accepts session_id, sets signed cookie with expiry

### Step 6 — Update pairing service
- Revoke existing sessions on re-pairing
- Create new session
- Broadcast session_id (safe — only useful signed)
- Update service spec

### Step 7 — Update heartbeat
- Update `last_active_at` on session
- Device info still updates on player
- Handle 401 in playback JS → redirect to pairing

### Step 8 — Update JS client
- Registration stores session_id for authenticate call
- Cookie key references throughout
- localStorage keeps `player_public_id`

### Step 9 — Admin dashboard
- PlayerSession Administrate dashboard
- Revoke action

### Step 10 — Update ActionCable
- Connection reads `:player_session_id` cookie

### Step 11 — Seeds, docs, ship
- Update seeds, CLAUDE.md, architecture docs
- `make lint`, `make test`
- Push, create PR

## After this ships

The hardening plan simplifies:
- **Token rotation** — handled naturally by session revoke + create
- **Cookie expiration** — set here (1 year)
- **Remaining items** (broadcast cleanup, PairingChannel validation,
  landing page check, rate limits) apply as-is

## Out of Scope

- Bearer token support (add `token` column to PlayerSession later
  when native apps need it)
- Session expiration by idle time (auto-revoke after N days)
- Multiple concurrent sessions per player
- Player session UI in the app (admin-only for now)
