# Plan: Codebase Cleanup

**Created:** 2026-09-17 (updated 2026-09-18)
**Status:** Draft
**Branch:** TBD

## Important (bugs / misleading)

### 1. Fix ad_pid vs ad_id bug in AdsController ✓

`App::AdsController#show` queries `where_properties(ad_id: @ad.id)`
but the JS sends `ad_pid` in impression events. Impression count on
the ad show page is always zero.

**Fix:** `where_properties(ad_pid: @ad.public_id)`

### 2. Remove Current.account_user from docs ✓

CLAUDE.md documents `Current.account_user` but it doesn't exist.
Can't implement because a user can have multiple `AccountUser`
records per account (one per role) — no single record to cache.

**Fix:** Remove `Current.account_user` references from CLAUDE.md.

**Future investigation:** Evaluate Rolify or similar gem to
consolidate roles into a single record per user-account pair.

## Minor (should fix)

### 3. Drop dead `impressions` table ✓

No model, no code references. Pre-Ahoy artifact.

**Fix:** Migration to drop the table.

### 4. Remove `players.token` column ✓

Generated but never read — auth goes through `PlayerSession` cookies.

**Fix:** Migration to remove column + index. Remove `generate_token`
callback and `token` validation from Player model.

### 5. Create Go::BaseController ✓

All four Go controllers independently skip auth and set layout.

**Fix:** `Go::BaseController < ApplicationController` with
`skip_before_action :require_authentication` and `layout "public"`.
`ExperiencesController` overrides with `layout "player"` for now.

**Note:** Both `public` and `player` layouts are interim. Eventually
Go pages should have their own `go` layout.

### 6. Extract shared Play/API logic into services ✓

Heartbeat and pairing code logic is duplicated between Play and API.

**Fix:** Two services following the Result struct pattern:
- `RecordHeartbeat` — updates session activity, player device info,
  parses UA if changed. Returns success/failure (unpaired = failure).
- `RefreshPairingCode` — returns existing code or generates new one.
  Returns pairing_code + expires_in.

Both Play and API controllers become thin wrappers.

### 7. Simplify Ahoy account context — separate plan

**Moved to:** `plan-ahoy-account-simplification.md`

### 8. Go experience page overhaul — separate plan

**Moved to:** `plan-go-experience.md`

### 9. IP/UA on PlayerSession — won't do

Revisit later. Moving IP/UA to session would break `player.ip_address`
reads in admin dashboard, screen helper, and other display contexts.
`last_heartbeat_at` must stay on Player for online status. Not worth
the complexity right now.

## Route renames ✓

Nested resources read as the resource concept, not the join model.

| Before | After | Controller |
|--------|-------|-----------|
| `resource :pair, controller: "pairings"` | `resource :pairing` | `PairingsController` |
| `resource :screen_player` under screens | `resource :player, controller: "screen_players"` | `ScreenPlayersController` |
| `resource :screen_content` under screens | `resource :content, controller: "screen_contents"` | `ScreenContentsController` |
| `resources :playlist_ads` under playlists | `resources :ads, controller: "playlist_ads"` | `PlaylistAdsController` |
| `resources :listing_agents` under listings | `resources :agents, controller: "listing_agents"` | `ListingAgentsController` |
| `resources :lead_agents` under leads | `resources :agents, controller: "lead_agents"` | `LeadAgentsController` |
| `resources :account_users` under users | `resources :roles, controller: "account_users"` | `AccountUsersController` |

## Player cleanup ✓

### 10. Rename ParseDeviceInfo → UpdateDeviceInfo

The service parses UA AND writes to DB. Name should reflect both.

### 11. Return expires_at instead of expires_in for pairing codes

Return ISO 8601 timestamp. Let JS calculate countdown. Avoids drift.

## Cosmetic ✓

### 12. leads.context — add store_accessor

Use `store_accessor :context, :source_url, :ip_address, :user_agent`
for named attribute access instead of hash access.

### 13. Delete hello_controller.js

Dead Stimulus scaffold code.

### 14. Merge listing_tenant_scoping_spec into listing_spec

Breaks the one-spec-per-model convention. Merge under a context.

### 15. Clean up stale route comments in controllers

Several controllers have comments referencing old route paths.

## Execution

### Phase 1 — Fix bugs
- Fix ad_pid query (#1)
- Remove Current.account_user from docs (#2)

### Phase 2 — Drop dead code
- Drop impressions table (#3)
- Remove players.token (#4)
- Delete hello_controller.js (#13)

### Phase 3 — Structural improvements
- Go::BaseController (#5)
- Extract RecordHeartbeat + RefreshPairingCode services (#6)

### Phase 4 — Route renames
- All route renames with controller: overrides
- Update path helpers in views and specs

### Phase 5 — Player cleanup
- Rename ParseDeviceInfo → UpdateDeviceInfo (#10)
- expires_at for pairing codes (#11)

### Phase 6 — Cosmetic
- leads.context store_accessor (#12)
- Merge listing scoping spec (#14)
- Stale comments (#15)

## Won't do
- #9 IP/UA on PlayerSession — revisit later
- #12 (old) listing_agents.primary_at — keep as datetime, provides ordering context

## Spun off into own plans
- #7 Ahoy account simplification → `plan-ahoy-account-simplification.md`
- #8 Go experience overhaul → `plan-go-experience.md`
- Rolify investigation → future
