# Plan: App UX Fixes (Draft)

## Problem

The app has hardcoded placeholder data presented as real, broken
form fields, dead buttons, missing states, and inconsistent patterns.
These need to be fixed before production launch — users will lose
trust seeing fake data or clicking buttons that do nothing.

---

## Critical — must fix before going live

### 1. Remove dead screen_players/new pairing view
**Page:** `screen_players/new`, `App::ScreenPlayersController#new`
**Issue:** Nothing in the app links to this view. The `/pair` route
replaced it. The view still references `replay.com/player` (wrong URL).
Dead code that confuses the codebase.
**Fix:** Remove `new` action from `ScreenPlayersController`, remove
`screen_players/new.html.erb`, remove `new` from the route
(`only: %i[create destroy]`). Keep `create` and `destroy` — those
are used by the `/pair` flow and unpair.

### 2. Listing form description textarea is broken
**Page:** `listings/_form`
**Issue:** `form.text_area :address` with `disabled: true`, `name: nil`,
`id: nil`. Labeled "Description" but maps to the wrong field and never
submits. Users type into it and nothing saves.
**Fix:** Either add a `description` column to Listing and wire it up
properly, or remove the textarea entirely.

### 3. Heartbeat display is hardcoded
**Page:** `screens/index` (grid + table views)
**Issue:** "Heartbeat 12s ago" and "12s ago" are literal strings, not
read from `player.last_heartbeat_at`. Every screen shows the same text.
**Fix:** Show real heartbeat data with `time_ago_in_words`. Display four
distinct states:
- **No player** (gray) — "No player assigned"
- **Offline** (red/amber) — "Last seen {time_ago}" or "Never connected"
- **Online** (blue) — "Heartbeat {time_ago}"
- **Live** (green) — "Heartbeat {time_ago}"

Applies to both grid and table views. Use `screen.player&.last_heartbeat_at`
with `time_ago_in_words`. Status badge and heartbeat row logic update together.

### 4. Fake event log on screen detail
**Page:** `screens/show`
**Issue:** "Event log" section is a hardcoded Ruby array with fake
entries ("Screen registered — just now", "Playlist published — 2m ago").
Every screen shows identical fake activity.
**Fix:** Either replace with real paper_trail versions for the screen
and its associations, or remove the section entirely. A half-baked
activity log is worse than none.

---

## Important — fix soon

### 5. Hardcoded uptime on screen detail
**Page:** `screens/show`
**Issue:** Uptime stat shows "99.4%" for every screen. Not calculated.
**Fix:** Calculate from heartbeat history, or remove the stat until
real uptime tracking exists.

### 6. Hardcoded schedule panel on screen detail
**Page:** `screens/show`
**Issue:** Schedule card shows "Daily · 8:00 AM – 9:00 PM" and
"America/New_York" for every screen. No schedule model exists.
**Fix:** Remove the panel or replace with "Coming soon" placeholder.
Day-parting is a separate roadmap item.

### 7. Sites subtitle shows wrong player count
**Page:** `sites/index`
**Issue:** "players online" equals total screen count. Not computed.
**Fix:** Query actual online players.

### 8. Site card/show "N/N live" always matches screen count
**Page:** `sites/_site_card`, `sites/show`
**Issue:** Live count = screen count regardless of actual player status.
**Fix:** Count screens with active online players.

### 9. Site show "Scans (mo)" hardcoded 0
**Page:** `sites/show`, `sites/_site_card`
**Issue:** Scan count shows 0 with no query.
**Fix:** Query qualified scans for the site's screens in last 30 days.

### 10. Listing hardcoded property details
**Page:** `listings/show`
**Issue:** Property type always "Apartment", year built "—",
neighborhood "—", days on market "0", MLS# fake "RP-XXXXX".
Features & amenities shows same 6 items for every listing.
**Fix:** Remove stubbed sections that imply data exists when it
doesn't. Add real fields to Listing model when ready, or show
only fields that have actual data.

### 11. "About this property" auto-generated boilerplate
**Page:** `listings/show`
**Issue:** Template generates "This 3-bedroom, 2-bathroom apartment..."
No `description` field on Listing. Says "apartment" for all types.
**Fix:** Remove auto-generated text. Add `description` field when ready.

### 12. Dead buttons — "Sync MLS"
**Page:** `listings/index`
**Issue:** Button has no action — no href, no form, no controller.
**Fix:** Remove until MLS integration is built.

### 13. Dead kebab menus — listings and playlists tables
**Page:** `listings/index` (table), `playlists/index`
**Issue:** Three-dot buttons stop propagation but show no dropdown.
**Fix:** Wire up dropdown with Edit/Delete, or remove the buttons.

### 14. No team member removal or role change
**Page:** `users/index`, `users/show`
**Issue:** Can invite but can't remove or change roles.
**Fix:** Add "Remove from account" and role change actions.

### 15. No invite resend
**Page:** `invites/index`
**Issue:** Only "Revoke" available. No "Resend".
**Fix:** Add resend action that generates a new email.

### 16. Dashboard queries in view
**Page:** `app/views/app/dashboard/show.html.erb`
**Issue:** Chart queries run directly in the view template.
**Fix:** Move to controller.

### 17. Playlists index "just now" timestamp
**Page:** `playlists/index`
**Issue:** Every playlist shows "just now" regardless of when modified.
**Fix:** Use `time_ago_in_words(playlist.updated_at)`.

### 18. ~~Two parallel pairing flows~~ (resolved by item #1)
Removing `screen_players/new` eliminates the duplicate. The `/pair`
route is the single pairing flow.

### 19. Screen show preview is useless
**Page:** `screens/show`
**Issue:** Preview area shows text "Preview" or "—". No actual content.
**Fix:** Render thumbnail of current playlist's first ad, or iframe.

### 20. Screen table "Player" column always blank
**Page:** `screens/index` (table view)
**Issue:** Player column always "—" even when paired.
**Fix:** Show "Paired" / "Not paired" or player token (truncated).

### 21. Status label mismatch in listing form vs filter
**Page:** `listings/_form`, `listings/index`
**Issue:** Form offers "For Rent" (value: "pending"). Filter offers
"Pending". Same status, different labels.
**Fix:** Align labels and values.

### 22. QR code — no toggle active/inactive
**Page:** `qr_codes/show`
**Issue:** Shows status badge but no action to change it.
**Fix:** Add toggle button.

### 23. Mobile responsiveness — screen stats
**Page:** `screens/show`
**Issue:** `grid grid-cols-4` with no responsive breakpoints.
**Fix:** `grid-cols-2 sm:grid-cols-4`

### 24. Mobile responsiveness — listing spec strip
**Page:** `listings/show`
**Issue:** 5 flex items in one row, no wrapping.
**Fix:** Responsive grid.

### 25. Agent show — stubbed performance card
**Page:** `agents/show`
**Issue:** Placeholder gray box, hardcoded zeros.
**Fix:** Show real counts or remove until analytics exist.

### 26. Dashboard `@leads_unread` computed but never displayed
**Page:** `app/dashboard/show`
**Issue:** Controller loads it but view never uses it.
**Fix:** Show unread badge on Leads stat card.

---

## Nice to have

### 27. No lead search or export
No search by name/email. No CSV export.

### 28. No photo removal on listing edit
Can upload but can't remove individual photos.

### 29. Dead agent "Message" and "Call" buttons
Buttons with no action on agents/show.

### 30. "Published v1" version label hardcoded
No versioning exists on playlists.

### 31. "Brokerage" site type badge hardcoded
No `site_type` field on Site.

### 32. Ad "Campaign" column always blank
No Campaign model exists.

### 33. Dashboard charts — no empty state
New account sees blank chart frames.

### 34. Dashboard stat cards not clickable
Should link to respective index pages.

### 35. Sidebar active state for nested controllers
`listing_agents`, `lead_agents`, `qr_scans` don't highlight parent.

### 36. Flash partial only handles notice and alert
`flash[:warning]` or `flash[:info]` silently dropped.

### 37. Listing rental detection heuristic
`price < 100_000` = rental. Fragile assumption.

### 38. Home/index scaffold page
"Welcome. Your application is ready." — leftover scaffold.

---

## Build order

### Phase 1 — Remove fake data and dead UI (critical)

1. Fix screen pairing instructions URL
2. Fix or remove listing description textarea
3. Replace hardcoded heartbeat with real `last_heartbeat_at` + four states
4. Remove or replace fake event log on screen detail
5. Remove hardcoded uptime stat
6. Remove hardcoded schedule panel
7. Remove dead buttons (Sync MLS, kebab menus, agent Message/Call)
8. Remove hardcoded listing property stubs (features, about, type)

### Phase 2 — Fix real data display

9. Fix sites player count and live count
10. Fix sites scan count
11. Fix playlists timestamp
12. Fix screen table player column
13. Fix status label mismatch (listing form vs filter)
14. Move dashboard chart queries to controller
15. Show `@leads_unread` on dashboard
16. Fix agent performance card (real data or remove)

### Phase 3 — Missing functionality

17. Team member removal and role change
18. Invite resend
19. QR code active/inactive toggle
20. Consolidate pairing flows
21. Screen preview (thumbnail or iframe)

### Phase 4 — Mobile and polish

22. Mobile responsive fixes (screen stats, listing spec strip)
23. Dashboard empty states and clickable stat cards
24. Sidebar active state fixes
25. Lead search
26. Flash partial — support warning/info types
27. Remove scaffold home page
