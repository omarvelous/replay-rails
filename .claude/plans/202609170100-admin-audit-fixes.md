# Plan: Admin Panel Audit Fixes

## Context

The admin audit (`.claude/analysis/admin-audit.md`) scored 2.8/5.
9 resources are inaccessible (routes missing), `public_id` is
invisible on all 27 dashboards, and several dashboards are stale
after recent model changes (QR refactoring, agent bio, listing
types).

---

## Phase 1: Missing Routes

**File:** `config/routes.rb`

Add routes for 10 resources that have controllers + dashboards
but no routes:

```ruby
constraints subdomain: "admin" do
  scope module: "admin", as: "admin" do
    # ... existing routes ...

    # Ad types (nested under ads namespace)
    namespace :ads do
      resources :listing_ads
      resources :agent_ads
      resources :brand_ads
      resources :collection_ads
      resources :collection_ad_ads
    end

    # Joins and history
    resources :listing_agents
    resources :playlist_ads
    resources :screen_players
    resources :screen_contents
    resources :sessions, only: %i[index show destroy]
  end
end
```

Sessions should be read + destroy only (admin can view and
revoke sessions, not create them).

---

## Phase 2: `public_id` on All Dashboard SHOW Pages

Add `:public_id` to `SHOW_PAGE_ATTRIBUTES` on every dashboard.
Should NOT be in `FORM_ATTRIBUTES` (auto-generated) or
`COLLECTION_ATTRIBUTES` (too noisy for index tables).

**Dashboards to update (all of them):**

- AccountDashboard
- AccountUserDashboard
- AdDashboard
- Ads::AgentAdDashboard
- Ads::BrandAdDashboard
- Ads::CollectionAdDashboard
- Ads::CollectionAdAdDashboard
- Ads::ListingAdDashboard
- AgentDashboard
- ExperienceDashboard
- InquiryDashboard
- InviteDashboard
- LeadDashboard
- LeadAgentDashboard
- ListingDashboard
- ListingAgentDashboard
- PlayerDashboard
- PlaylistDashboard
- PlaylistAdDashboard
- QrCodeDashboard
- ScreenDashboard
- ScreenContentDashboard
- ScreenPlayerDashboard
- SessionDashboard
- SiteDashboard
- UserDashboard

26 dashboard files. Mechanical change — add `:public_id` after
`:id` in each SHOW_PAGE_ATTRIBUTES array.

---

## Phase 3: Missing Dashboard Fields

### 3a. ListingDashboard

**File:** `app/dashboards/listing_dashboard.rb`

Add to ATTRIBUTE_TYPES:
```ruby
description: Field::Text,
listing_type: Field::String,
property_type: Field::String,
listing_agents_count: Field::Number,
```

Add to SHOW_PAGE_ATTRIBUTES and FORM_ATTRIBUTES:
`:description`, `:listing_type`, `:property_type`

Add to SHOW_PAGE_ATTRIBUTES only:
`:listing_agents_count`

### 3b. QrCodeDashboard

**File:** `app/dashboards/qr_code_dashboard.rb`

Add to ATTRIBUTE_TYPES:
```ruby
creative: Field::Polymorphic,
screen_content: Field::BelongsTo,
```

Add to SHOW_PAGE_ATTRIBUTES:
`:creative`, `:screen_content`

### 3c. AgentDashboard

**File:** `app/dashboards/agent_dashboard.rb`

Add to ATTRIBUTE_TYPES:
```ruby
bio: Field::Text,
```

Add to SHOW_PAGE_ATTRIBUTES and FORM_ATTRIBUTES:
`:bio`

### 3d. PlayerDashboard

**File:** `app/dashboards/player_dashboard.rb`

Add to ATTRIBUTE_TYPES:
```ruby
pairing_code_expires_at: Field::DateTime,
firmware_version: Field::String,
```

Add to SHOW_PAGE_ATTRIBUTES:
`:pairing_code_expires_at`, `:firmware_version`

### 3e. ExperienceDashboard — JSONB field

**File:** `app/dashboards/experience_dashboard.rb`

Change `config` from `Field::String` to `Field::Text` for
readable JSONB rendering.

### 3f. LeadDashboard — JSONB field

**File:** `app/dashboards/lead_dashboard.rb`

Change `context` from `Field::String` to `Field::Text`.

---

## Phase 4: Add Standard for Admin Dashboard Maintenance

Add a rule to the existing model conventions standard or create
an admin-specific checklist:

> When adding a column to a model, update the corresponding
> Administrate dashboard:
> 1. Add to `ATTRIBUTE_TYPES`
> 2. Add to `SHOW_PAGE_ATTRIBUTES` (always)
> 3. Add to `FORM_ATTRIBUTES` (if editable)
> 4. Add to `COLLECTION_ATTRIBUTES` (if useful on index)

This prevents the drift that caused these gaps.

---

## Build Order

### Phase 1: Routes

```
1. Add 10 missing admin routes
2. Run tests — verify no routing conflicts
3. COMMIT
```

### Phase 2: public_id

```
4. Add :public_id to SHOW_PAGE_ATTRIBUTES in all 26 dashboards
5. COMMIT
```

### Phase 3: Missing fields

```
6. ListingDashboard: description, listing_type, property_type
7. QrCodeDashboard: creative, screen_content
8. AgentDashboard: bio
9. PlayerDashboard: pairing_code_expires_at, firmware_version
10. ExperienceDashboard: config → Text
11. LeadDashboard: context → Text
12. COMMIT
```

### Phase 4: Standard update

```
13. Add admin dashboard maintenance rule to standards
14. COMMIT
```

---

## Verification

1. `make test` — green
2. Visit admin panel — all 24 resources appear in navigation
3. Click through each resource — no 500 errors
4. Listing show page displays description, listing_type, property_type
5. QrCode show page displays creative and screen_content
6. All show pages display public_id
7. Agent show page displays bio

---

## Expected Score After Fixes

| Category | Before | After |
|----------|:------:|:-----:|
| Route coverage | 2 | 5 |
| Dashboard coverage | 3 | 5 |
| Field coverage | 2 | 5 |
| Form completeness | 3 | 4 |
| Dashboard controller | 4 | 4 |
| **Overall** | **2.8** | **4.6** |
