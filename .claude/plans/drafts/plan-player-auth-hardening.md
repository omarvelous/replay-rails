# Plan: Player Auth Hardening

**Created:** 2026-09-16
**Status:** Draft
**Branch:** `player-auth-hardening`

## Problem

Security audit of the player pairing and authentication flow identified
four important issues and three minor ones. No critical vulnerabilities,
but these fixes close gaps before production launch.

## Important Fixes

### 1. Remove token from pairing broadcast

`PairPlayerToScreen` broadcasts `{ paired: true, token: player.token }`
on the PairingChannel. The JS client only checks `msg.paired` — it
already has the token from registration. The PairingChannel allows
unauthenticated subscriptions, so anyone who guesses the 6-char code
could intercept the token.

**Fix:** Remove `token` (and any other sensitive data) from the
broadcast payload. Only send `{ paired: true }`.

**File:** `app/services/pair_player_to_screen.rb`

### 2. Set cookie expiration

The `player_token` cookie has no `expires` — it's a session cookie
that disappears when the browser closes. On Fire TV Silk or Android
WebView, "closing the browser" is unpredictable. These are long-lived
device tokens that should persist.

**Fix:** Add `expires: 1.year.from_now` to the cookie options in
the Play `authenticate` action.

**File:** `app/controllers/play/players_controller.rb`

### 3. Validate PairingChannel subscriptions

Any WebSocket connection can subscribe to `pairing_#{code}` without
checking if the code is real or active. Combined with issue #1, this
allows token interception.

**Fix:** Look up the pairing code in the database and reject the
subscription if the code doesn't exist or is expired.

**File:** `app/channels/pairing_channel.rb`

### 4. Token rotation on re-pairing

Player tokens are generated once at creation and never change. A
leaked token grants permanent access with no way to revoke it short
of deleting the player record.

**Fix:** Add `rotate_token!` to Player that generates a new token.
Call it in `PairPlayerToScreen#call` after pairing. The device gets
the new token on the next `/players/authenticate` call (which happens
after `onPaired()` fires — the JS should call authenticate again
before redirecting).

**Files:** `app/models/player.rb`, `app/services/pair_player_to_screen.rb`,
`app/javascript/controllers/device_pairing_controller.js`

## Minor Fixes

### 5. Landing page cookie check

If localStorage has `player_public_id` but the cookie is cleared,
the landing page redirects to `/players/new` and re-registers —
orphaning the old player. Could check the cookie first.

**Fix:** In the landing page script, attempt a fetch to
`/v1/player` before redirecting to `/players/new`. If 401,
clear localStorage and redirect to new. If 200, redirect to
`/players/${publicId}`.

**File:** `app/views/play/players/landing.html.erb`

### 6. Explicit rescue in ActionCable connection

The bare `rescue` in `ApplicationCable::Connection#connect` catches
all exceptions including `Exception` subclasses (SignalException, etc.).

**Fix:** Change to `rescue StandardError`.

**File:** `app/channels/application_cable/connection.rb`

### 7. Rate limit on authenticate endpoint

The `/players/authenticate` endpoint has no rate limit. Token entropy
(256 bits) makes brute-force infeasible, but defense in depth is good.

**Fix:** Add `rate_limit to: 10, within: 1.minute, only: :authenticate`.

**File:** `app/controllers/play/players_controller.rb`

## Execution

### Step 1 — Remove token from pairing broadcast
- Update `PairPlayerToScreen` to broadcast only `{ paired: true }`
- Update spec

### Step 2 — Set cookie expiration
- Add `expires: 1.year.from_now` to cookie in `authenticate` action
- Update spec to verify expiry is set

### Step 3 — Validate PairingChannel subscriptions (TDD)
- **RED:** Channel spec asserting invalid/expired codes are rejected
- **GREEN:** Add code lookup + expiry check in `PairingChannel#subscribed`

### Step 4 — Token rotation on re-pairing (TDD)
- **RED:** Model spec for `Player#rotate_token!`, service spec asserting token changes on pairing
- **GREEN:** Implement `rotate_token!`, call in `PairPlayerToScreen`
- Update pairing JS to call `/players/authenticate` after pairing completes (before redirect)

### Step 5 — Landing page cookie check
- Update landing page script to fetch API status before defaulting to re-registration

### Step 6 — Explicit rescue + rate limit
- Change bare `rescue` to `rescue StandardError` in connection.rb
- Add rate limit to authenticate action

### Step 7 — Ship
- `make lint`, `make test`
- Push, create PR
