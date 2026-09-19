# Plan v2: Player Auth Hardening

**Created:** 2026-09-16 (v1), **Updated:** 2026-09-19 (v2)
**Status:** Draft

## Context

v1 identified 7 issues. Since then, the auth architecture changed
significantly:

- `PlayerSession` model exists — cookie-based auth via signed
  `player_session_id` cookie
- `RegisterPlayer` service creates player + session together
- `PlayerAuthentication` concern handles session resume from cookie
- Cookie has `expires: 1.year.from_now`, `httponly`, `secure`
- `PairPlayerToScreen` service handles pairing orchestration
- Rate limit on player registration

**Already resolved (3 of 7):**
- ~~Issue #2 (cookie expiry)~~ — `expires: 1.year.from_now` set
- ~~Issue #6 (bare rescue)~~ — already `rescue StandardError`
- ~~Issue #7 (rate limit)~~ — already on `create` action

**Still open (3 issues, updated for new architecture):**

---

## Issue 1: Sensitive data in pairing broadcast

**Current:** `PairPlayerToScreen` broadcasts:
```ruby
ActionCable.server.broadcast("pairing_#{@code}", {
  paired: true,
  session_id: new_session.id
})
```

`session_id` is a `PlayerSession` integer ID. The `PairingChannel`
allows unauthenticated subscriptions, so anyone who guesses the
6-char code could intercept this ID. Combined with issue #2, this
is exploitable.

**Fix:** Broadcast only `{ paired: true }`. The device already has
its session cookie from registration — it doesn't need the session
ID from the broadcast. The JS `onPaired()` handler just redirects
to `/player` which authenticates via the cookie.

**File:** `app/services/pair_player_to_screen.rb`

---

## Issue 2: PairingChannel accepts any code

**Current:** `PairingChannel#subscribed` streams from any code
without verification:

```ruby
def subscribed
  code = params[:code]
  stream_from "pairing_#{code}" if code.present?
end
```

Anyone can subscribe to `pairing_ABCDEF` without the code being
real or active. With issue #1 fixed (no session_id in broadcast),
the impact is reduced — an attacker learns when *some* device gets
paired, but can't hijack the session. Still worth fixing for
defense in depth.

**Fix:** Look up the code and reject if invalid/expired:

```ruby
def subscribed
  code = params[:code]
  player = Player.find_by(pairing_code: code)

  if player&.pairing_code_valid?
    stream_from "pairing_#{code}"
  else
    reject
  end
end
```

**File:** `app/channels/pairing_channel.rb`

---

## Issue 3: Revoke old sessions on re-pairing

**Current:** When a player is re-paired (e.g., moved to a different
screen), old `PlayerSession` records remain active. If a device's
cookie is compromised, the session can't be invalidated without
manually finding and revoking it.

`PairPlayerToScreen` unpairs old screen assignments but doesn't
touch sessions.

**Fix:** Revoke all active sessions for the player when re-pairing.
The device's next request to `/player` will fail auth (session
revoked), redirect to `/player/new`, and re-register with a fresh
session. The device self-heals on next page load.

```ruby
# In PairPlayerToScreen#call, after pairing:
player.player_sessions.active.each(&:revoke!)
```

Add convenience method to Player:

```ruby
def revoke_all_sessions!
  player_sessions.active.each(&:revoke!)
end
```

**Files:** `app/services/pair_player_to_screen.rb`,
`app/models/player.rb`

---

## Bonus: Landing page resilience

**Current behavior when cookie is cleared but device was paired:**

1. Device loads `/` (landing page)
2. Landing JS checks for `player_session_id` cookie — missing
3. Redirects to `/player/new` — registers as new player
4. Old player record orphaned

This is acceptable — `PlayerCleanupJob` handles orphans. The
current `device_pairing_controller.js` checks `localStorage`
before registering. Verify this path works correctly after session
revocation (issue #3).

**No code change needed** — just verification in specs.

---

## Build Order

```
1. Remove session_id from pairing broadcast
2. Update PairPlayerToScreen spec
3. COMMIT

4. RED:  PairingChannel spec — invalid/expired codes rejected
5. GREEN: Add code validation in PairingChannel#subscribed
6. COMMIT

7. Add Player#revoke_all_sessions!
8. Call in PairPlayerToScreen after pairing
9. Update specs
10. COMMIT
```

---

## Verification

1. `make test` — green
2. Pair a device — broadcast contains only `{ paired: true }`
3. Subscribe to PairingChannel with invalid code — rejected
4. Re-pair a device — old sessions revoked
5. Device with revoked session loads `/` — re-registers cleanly

---

## Files Changed

| File | Change |
|------|--------|
| `app/services/pair_player_to_screen.rb` | Remove session_id from broadcast, revoke old sessions |
| `app/channels/pairing_channel.rb` | Validate code before subscribing |
| `app/models/player.rb` | Add `revoke_all_sessions!` |
| `spec/services/pair_player_to_screen_spec.rb` | Update broadcast assertion, add session revocation test |
| `spec/channels/pairing_channel_spec.rb` | Add rejection tests |
| `spec/models/player_spec.rb` | Add revoke_all_sessions! test |
