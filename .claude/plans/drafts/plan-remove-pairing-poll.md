# Plan: Remove Pairing Status Poll

**Created:** 2026-10-01
**Status:** Draft
**Branch:** TBD

## Problem

The `checkStatus` poll in `device_pairing_controller.js` hits
`GET /api/v1/player` every 3 seconds for every unpaired device.
After the pairing session fix, the poll is dead on arrival —
revoking sessions invalidates the cookie, so the poll gets 401
and backs off forever. It never discovers pairing. It's dead
weight that burns API calls.

## Current pairing detection paths

1. **ActionCable broadcast** — instant, primary path (includes bearer token)
2. **Poll `GET /api/v1/player`** — fallback every 3s, broken post-revocation
3. **`checkIfPaired` on page load** — runs once on connect for page refresh recovery

Path 2 is the one to remove. Paths 1 and 3 cover all cases.

## What to remove from `device_pairing_controller.js`

```
connect():
  - this.pollDelay = 3000
  - this.schedulePoll()

disconnect():
  - clearTimeout(this.pollTimeout)

onPaired():
  - clearTimeout(this.pollTimeout)

Methods to delete entirely:
  - schedulePoll()
  - checkStatus()
  - backoff()
```

## What stays

- `checkIfPaired()` — page refresh recovery on connect
- `subscribeToPairing()` — primary real-time path
- `onPaired(token)` — transition handler (minus pollTimeout cleanup)
- `startCountdown()` / `onCodeExpired()` — code expiry refresh
- `registerNewPlayer()` / `refreshPairingCode()` — registration

## Risk

If ActionCable disconnects silently and the device misses the
broadcast, it stays on the pairing screen until the code expires
(5 min), at which point `onCodeExpired` refreshes the code. But
`checkIfPaired` only runs on initial connect, not on code refresh.

**Mitigation:** ActionCable auto-reconnects on disconnect. The
subscription is re-established automatically. If a broadcast was
missed during the gap, the next code expiry cycle (5 min max)
will call `refreshPairingCode` which hits the API with the cookie
— if pairing already happened, the server could detect this.

Alternatively, add a `checkIfPaired()` call inside `onCodeExpired`
before refreshing the code, so every 5-minute cycle also checks
pairing status. Belt and suspenders.

## Execution

```
1. Remove poll code from device_pairing_controller.js
2. Add checkIfPaired() call to onCodeExpired() as safety net
3. Manual test: pair a device, verify transition works via ActionCable
4. COMMIT
```

## Tests

No backend changes needed. JS-only change. Manual verification
of the pairing flow on a real device.
