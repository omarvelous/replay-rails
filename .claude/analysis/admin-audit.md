# Analysis: Admin Panel Audit

## Overview

The admin panel uses Administrate with 29 dashboard definitions
and 14 routed resources. The audit found significant gaps between
the schema/models and what the admin exposes.

---

## Scorecard

| Category | Score | Summary |
|----------|:-----:|---------|
| Route coverage | 2 | 9 controllers exist with no routes — inaccessible |
| Dashboard coverage | 3 | 4 models have no dashboard at all |
| Field coverage | 2 | `public_id` missing from SHOW on all 27 dashboards. Multiple schema fields missing. |
| Form completeness | 3 | Listing form missing description/property_type/listing_type. QrCode missing creative fields. |
| Dashboard controller | 4 | Stats are reasonable. Missing some operational metrics. |
| **Overall** | **2.8** | |

---

## P0 — Missing Admin Routes

9 controllers have dashboards defined but no routes — they're
completely inaccessible:

| Controller | Dashboard | Why it matters |
|-----------|-----------|----------------|
| `agent_ads` | `Ads::AgentAdDashboard` | Can't inspect agent ad type details |
| `brand_ads` | `Ads::BrandAdDashboard` | Can't inspect brand ad type details |
| `collection_ads` | `Ads::CollectionAdDashboard` | Can't inspect collection ad details |
| `collection_ad_ads` | `Ads::CollectionAdAdDashboard` | Can't inspect collection membership |
| `listing_ads` | `Ads::ListingAdDashboard` | Can't inspect listing ad badges/events |
| `listing_agents` | `ListingAgentDashboard` | Can't audit agent-listing assignments |
| `playlist_ads` | `PlaylistAdDashboard` | Can't audit playlist composition |
| `screen_players` | `ScreenPlayerDashboard` | Can't audit pairing history |
| `sessions` | `SessionDashboard` | Can't audit active sessions |

**Fix:** Add routes to `config/routes.rb` admin section:

```ruby
# Content (nested ad types)
namespace :ads do
  resources :listing_ads
  resources :agent_ads
  resources :brand_ads
  resources :collection_ads
  resources :collection_ad_ads
end

# Joins/history
resources :listing_agents
resources :playlist_ads
resources :screen_players
resources :sessions
```

---

## P0 — `public_id` Missing from All Dashboard SHOW Pages

Every model has `public_id` in `ATTRIBUTE_TYPES` but it's not in
`SHOW_PAGE_ATTRIBUTES` on any of the 27 dashboards. Admins can't
see or copy the UUID that's used in every URL, API response, and
analytics event.

**Fix:** Add `:public_id` to `SHOW_PAGE_ATTRIBUTES` in all
dashboards. Should NOT be in `FORM_ATTRIBUTES` (auto-generated).

---

## P1 — Missing Dashboard Fields

### Listing Dashboard

Missing from both SHOW and FORM:
- `description` (text — the property description)
- `listing_type` (for_sale/for_rent/for_lease)
- `property_type` (house/condo/townhouse/etc.)

These are core business fields. An admin can't see or edit the
listing type from the admin panel.

### QrCode Dashboard

Missing from SHOW:
- `creative_id` / `creative_type` (polymorphic — which ad/experience)
- `screen_content_id` (which screen content generated this QR)

These were added in recent QR refactoring and the dashboard wasn't
updated.

### Agent Dashboard

Missing from SHOW:
- `bio` (text — agent biography, recently added)

### Player Dashboard

Missing from SHOW:
- `pairing_code_expires_at` (when the code expires)
- `firmware_version`

### Experience Dashboard

- `config` shown as String but is JSONB — will render as a raw
  JSON blob. Needs a custom field renderer or at minimum
  `Field::Text` for readability.

### Lead Dashboard

- `context` shown as String but is JSONB — same issue.

---

## P2 — Missing Dashboards

4 models have schema tables and model files but no Administrate
dashboard:

| Model | Table | Why it matters |
|-------|-------|----------------|
| `Experiences::ListingExperience` | `listing_experiences` | Can't audit experience-listing linkage |
| `ScreenContent` | `screen_contents` | Dashboard exists but missing from audit concerns |
| `MetricSnapshot` | `metric_snapshots` | Can't audit historical metrics |
| `Impression` | `impressions` | Can't audit ad impression data |

**Note:** `ScreenContent` does have a dashboard — the audit agent
may have miscounted. Verify `Impression` and `MetricSnapshot` — if
these models are query-only (no AR model), they may not need
dashboards.

---

## P3 — Dashboard Controller Stats

Current stats tracked:

```
Infrastructure: accounts, players, players_online, screens
Funnel: impressions (total/today), scans (total/today), leads (week/unread)
Content: ads, listings, playlists, qr_codes
Activity: recent PaperTrail versions
```

Missing operational metrics:
- Screens by status (live/idle/offline)
- Players by device_type distribution
- Listings by status (active/pending/sold)
- Accounts by size (listings count, agents count)

These are nice-to-have, not blocking.

---

## Priority Fix Order

### Phase 1: Routes + public_id (biggest impact, smallest effort)

```
1. Add 10 missing admin routes
2. Add :public_id to SHOW_PAGE_ATTRIBUTES in all dashboards
3. COMMIT
```

### Phase 2: Missing fields

```
4. Listing dashboard: add description, listing_type, property_type
5. QrCode dashboard: add creative_type, creative_id, screen_content_id
6. Agent dashboard: add bio
7. Player dashboard: add pairing_code_expires_at
8. COMMIT
```

### Phase 3: JSONB field rendering

```
9. Experience config: change from String to Text
10. Lead context: change from String to Text
11. COMMIT
```

---

## Files to Change

| File | Changes |
|------|---------|
| `config/routes.rb` | Add 10 admin routes |
| 27 dashboard files in `app/dashboards/` | Add `:public_id` to SHOW |
| `app/dashboards/listing_dashboard.rb` | Add missing fields |
| `app/dashboards/qr_code_dashboard.rb` | Add creative/screen_content fields |
| `app/dashboards/agent_dashboard.rb` | Add bio |
| `app/dashboards/player_dashboard.rb` | Add pairing_code_expires_at |
| `app/dashboards/experience_dashboard.rb` | Change config to Text |
| `app/dashboards/lead_dashboard.rb` | Change context to Text |
