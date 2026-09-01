# Plan: Player UX Improvements (Draft)

## Problem

The player device lifecycle has several gaps between "works in demo"
and "works unattended in a storefront window 24/7." These range from
missing real-time event handling to visual bugs to API error handling.

## Current state

The player has four states rendered server-side:

| State | View | Condition |
|-------|------|-----------|
| Pairing | `new.html.erb` | No token — shows 6-char code |
| Idle | `idle.html.erb` | Paired, no playlist assigned |
| Playing | `show.html.erb` | Paired + playlist — slideshow |
| Unpaired | `unpaired.html.erb` | Token exists but no active ScreenPlayer |

**ActionCable events currently supported:**
- `PairingChannel` — broadcasts `{ paired: true }` when code is entered
- `ScreenChannel` — broadcasts `{ event: "playlist_changed" }` when ScreenPlaylist changes

**What's missing:** No event for unpair, no event for playlist assign
to an idle screen, no client-side handling of API errors, no recovery
from stale state.

---

## Items

### Critical — device can't run unattended without these

#### 1. React to unpair events
**Problem:** When a player is unpaired via the app, it keeps playing
ads indefinitely. It doesn't know it's been unpaired until the page
is manually reloaded.

**Fix:**
- `ScreenPlayer#unpair!` broadcasts `{ event: "unpaired" }` to
  `screen_#{screen_id}` via ActionCable
- `device_playback_controller.js` handles `unpaired` event:
  clear `localStorage` token, redirect to `/players/new`

#### 2. API resilience for unpaired players
**Problem:** After unpairing, slides keep running and fire heartbeat
+ impression requests. Impressions 500 with `NoMethodError: undefined
method 'site' for nil` because `@player.screen` returns nil.

**Fix:**
- `ImpressionsController#create` — guard: if `@player.screen` is nil,
  return `410 Gone` with `{ error: "unpaired" }`
- `HeartbeatsController#create` — same guard, return 410
- `device_playback_controller.js` — on 410 response from heartbeat
  or impression, stop playback, clear token, redirect to pairing

#### 3. Auto-reload on playlist assign (idle → playing)
**Problem:** A paired player showing "No content assigned" doesn't
auto-update when a playlist is assigned to its screen. Requires
manual page refresh or re-pair.

**Fix:**
- `ScreenPlaylist` already broadcasts `playlist_changed` on create
- But the idle view doesn't have the `device-playback` controller
  attached (no `data-controller` in `idle.html.erb`)
- Add the Stimulus controller to `idle.html.erb` so it listens for
  `playlist_changed` and reloads

#### 4. Device fingerprinting — one device = one Player record
**Problem:** Every page load of `/players/new` calls `POST /players`
and creates a new Player record. Unpaired players can't get a new
pairing code without registering again. This creates orphaned records,
DB bloat, and breaks the mental model of "one device = one player."

**Root cause:** "Register device" and "request pairing code" are
conflated in a single `POST /players` endpoint.

**Fix — separate the two concerns:**
- `POST /players` — register a new device (once). Returns `token`.
  Device stores token in `localStorage` permanently.
- `POST /players/:token/pairing_code` — generate a new pairing code
  for an existing player (repeatable). Calls `refresh_pairing_code!`
  which already exists on the model.
- `device_pairing_controller.js` — on connect, check `localStorage`
  for existing token:
  - Has token → call `POST /players/:token/pairing_code` to get a
    fresh code. Display it.
  - No token → call `POST /players` to register. Store token. Display
    code.
- After pairing, token stays in `localStorage`. After unpairing,
  device calls the pairing code endpoint again — same Player record,
  new code. No orphans.

**Lifecycle after fix:**
```
First visit    → POST /players           → token stored in localStorage
Need to pair   → POST /players/:token/pairing_code → new code displayed
Paired         → /players/:token          → playback
Unpaired       → POST /players/:token/pairing_code → new code, same player
Device reset   → POST /players           → new token (old player orphaned, cleanup job handles it)
```

**Also needed:**
- Cleanup job for players never paired after 24 hours (handles the
  rare case of device reset or localStorage cleared)
- Rack::Attack throttle fix: target `/players` not `/register`
- `pair_player!` wrapped in `with_lock` to prevent race conditions

#### 5. Smart caching with live updates
**Problem:** Player either shows stale cached content or requires a
full reload to pick up changes. Need to survive network blips but
also respond to server-side changes within seconds.

**Fix:**
- ActionCable is the live update channel — already handles playlist
  changes. Extend to cover: unpair, playlist content changes (ad
  added/removed/reordered), screen settings changes
- For offline resilience: Service Worker that caches the playlist
  page and image assets. If network drops, player keeps showing
  cached content. When network returns, ActionCable reconnects and
  pushes any changes.
- Phase this: ActionCable events first (items 1-3), Service Worker
  cache later (separate plan)

---

### Important — visual/UX bugs visible to end users

#### 5. Hide prev/next navigation in player mode
**Problem:** The slideshow shows "← Prev" and "Next →" buttons meant
for preview mode. These are visible on the TV screen.

**Fix:**
- Don't render nav controls in `play/players/show` — the play layout
  already implies it's a screen, not a preview. The nav block
  (lines 28-35 of `show.html.erb`) should only exist in the app
  preview partial, not the play view.

#### 6. QR code cropping
**Problem:** QR codes on ads are cropped or rendered at wrong aspect
ratio on screen. Not scannable from storefront.

**Fix:**
- Audit the `_qr_badge` partial sizing — likely an `overflow: hidden`
  or container constraint clipping the SVG
- QR badge needs fixed aspect ratio (1:1) with adequate padding
- Test scannability at 1080p from 3+ feet away

---

### Nice to have — polish for production readiness

#### 7. Play root route
**Problem:** `play.replaytv.co/` has no root route. Devices that
reboot or lose their URL have to know `/players/new`.

**Fix:**
- Add `root "players#landing"` to the play subdomain routes
- `landing` action renders a simple page with client-side JS:
  - Has token in `localStorage` → redirect to `/players/:token`
  - No token → redirect to `/players/new`
- No server-side session/cookie needed since token is in `localStorage`

#### 8. QR code on pairing screen
**Problem:** The pairing screen says "Enter this code at replay.com →
Screens" — wrong domain and requires staff to know the URL and type
the code manually.

**Fix:**
- Display a QR code on the pairing screen alongside the 6-char code
- QR links to `app.replaytv.co/pair?code=A7B3K2`
- New `/pair` route in the app — a dedicated page that:
  - Requires auth (redirects to login if not signed in, then back)
  - Shows available screens for the current account
  - Staff taps a screen → pairs the player with the embedded code
  - One scan, one tap — done
- Keep the text code visible as a fallback for staff already logged
  in on a desktop
- Update the instructional text from "Enter this code at replay.com"
  to "Scan to pair" with the text code shown smaller below

#### 9. Pairing code expiry countdown
**Problem:** The pairing screen says "Code expires in 10 minutes" as
static text. No visible countdown. If the code expires, the screen
shows a stale code that won't work.

**Fix:**
- Add a countdown timer in `device_pairing_controller.js`
- When timer hits zero, auto-register a new player and display the
  new code (seamless refresh)

#### 9. Offline/reconnect indicator
**Problem:** When WiFi drops, the player shows no indication. The
slideshow freezes on the current slide. Store staff has no way to
know if the screen is working or stuck.

**Fix:**
- Monitor ActionCable connection state
- After N seconds disconnected, show a subtle overlay:
  "Reconnecting..." with a spinner in the corner
- On reconnect, hide overlay and reload content
- Don't block the slideshow — keep playing cached slides while
  reconnecting

#### 10. Error states and self-recovery
**Problem:** Invalid token, expired pairing code, and network errors
show generic browser errors or blank screens. Fire TV Stick in kiosk
mode has no keyboard or address bar — the device must self-recover
without human interaction.

**Fix:**
- Invalid/deleted token on `/players/:token` → auto-redirect to
  `/players/new` (generate new player + new code). No button needed,
  no human interaction — the device self-recovers. The token only
  becomes invalid if the Player record is deleted (admin action),
  not during normal unpair flow.
- Expired pairing code → auto-register a new player and display
  the new code (handled by item 8, countdown + auto-refresh)
- Network error during pairing → show "Connecting..." with
  auto-retry on a loop. No user action needed.
- All error/recovery screens use the player layout (black background,
  centered white text) — not the default Rails error page
- **Design principle:** the device should never reach a dead-end
  state that requires physical interaction to recover from

---

## Build order

### Phase 1 — Critical fixes (TDD)

1. RED/GREEN: `ScreenPlayer#unpair!` broadcasts `{ event: "unpaired" }`
2. RED/GREEN: `ImpressionsController` returns 410 when player unpaired
3. RED/GREEN: `HeartbeatsController` returns 410 when player unpaired
4. RED/GREEN: Wrap `pair_player!` in `with_lock` to prevent race conditions
5. RED/GREEN: Fix Rack::Attack throttle — target `/players` not `/register`
6. Update `device_playback_controller.js`:
   - Handle `unpaired` ActionCable event → clear token, redirect
   - Handle 410 from heartbeat/impression → same
   - Handle rejected ScreenChannel subscription → redirect to pairing
7. Add `device-playback` controller to `idle.html.erb` for playlist
   assign auto-reload
8. `Play::BaseController` — invalid token returns redirect to `/players/new`
   instead of blank 401
9. Test on staging with Fire TV Stick

### Phase 2 — Device fingerprinting (TDD)

10. RED/GREEN: `POST /players/:token/pairing_code` endpoint
    (calls `refresh_pairing_code!`)
11. Update `device_pairing_controller.js`:
    - On connect, check `localStorage` for existing token
    - Has token → `POST /players/:token/pairing_code`
    - No token → `POST /players` → store token in `localStorage`
12. Play root route with `localStorage` redirect:
    - Has token → `/players/:token`
    - No token → `/players/new`
13. RED/GREEN: `PlayerCleanupJob` — delete players never paired after 24 hours
14. Test full lifecycle on staging: register → pair → unpair → re-pair (same player record)

### Phase 3 — Visual fixes

15. Remove nav controls from `play/players/show.html.erb`
16. Fix QR code badge sizing in `_qr_badge` partial
17. Test on staging — verify clean display, scannable QR codes

### Phase 4 — Pairing improvements

18. QR code on pairing screen with embedded pair link
19. Update instructional text ("Scan to pair")
20. App-side: `/pair?code=CODE` route — shows screens, pairs on tap

### Phase 5 — Polish

21. Pairing code countdown timer + auto-refresh (calls pairing_code
    endpoint, not new player registration)
22. Offline/reconnect overlay
23. Error state self-recovery (invalid token → auto-redirect, network → auto-retry)
24. `unpaired.html.erb` auto-redirects to `/players/new` after short delay

---

## Notes from audit

- `notify_player` on ScreenPlaylist destroy can cause double-reload
  when swapping playlists (two events fire in quick succession).
  Cosmetic — doesn't break anything. Consider debouncing later.
- Pairing code uniqueness collision on `refresh_pairing_code!` is
  theoretically possible (36^6 space) but extremely unlikely. Add
  a retry loop if it ever surfaces in production.
- `authorize! ScreenPlayer` passes the class not an instance in
  `ScreenPlayersController#new`. Works today but fragile if policy
  is customized. Fix opportunistically.
- Cross-tenant pairing theft: `Player.find_by(pairing_code:)` is a
  global lookup. A manager at Account A could enter Account B's code.
  Low risk since codes expire in 10 minutes and are random, but
  consider scoping or adding a claim check.
- `slideshow_controller.js` progress animation doesn't pause when
  tab is hidden — slides advance instantly on focus restore. Fix
  with a `visibilitychange` listener.
- `device_pairing_controller.js` polls at fixed 3s intervals with
  no backoff. 100 devices polling a down server = 2000 req/min.
  Add exponential backoff with 60s cap.
- ActionCable channel naming: `screen_#{id}` is subscribed to by
  the player device, not the admin UI. The channel is really "the
  device playing on this screen." Consider whether admin should
  also subscribe for real-time status updates (online/offline,
  playlist changes) instead of relying on heartbeat polling. Needs
  further evaluation.

---

## What's deferred

- **Service Worker caching** — offline resilience beyond "keep current slide visible." Requires a separate plan for cache strategy, asset manifest, and update flow.
- **Account-scoped players** — add `account_id` to Player so players belong to an account. Enables tenant-scoped pairing code lookup (prevents cross-tenant pairing), player inventory per account, and device management. Consider implications for hardware reassignment between accounts. Separate plan.
- **Remote device management** — restart, screenshot, diagnostics from the app dashboard. Separate feature.
- **Multi-screen sync** — synchronized playback across screens at the same site. Not needed for v1.
