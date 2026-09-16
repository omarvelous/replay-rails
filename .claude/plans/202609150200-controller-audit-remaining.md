# Plan: Controller Audit — Remaining Items

## Context

The controller audit started at 3.5/5 and is now at 4.5/5 after
PRs #60 (P0/P1) and #61 (P2 + standard). This plan covers the
remaining items needed to reach 5/5.

Two categories remain:
1. **Performance** (score 3 → unchanged) — the only category that
   didn't improve
2. **Housekeeping** — low-priority items deferred from P2

---

## Step 1 — Strict Loading + Bullet Gem

**Goal:** Catch N+1 queries automatically in development and test.

### 1a. Bullet gem

**File:** `Gemfile`

```ruby
group :development, :test do
  gem "bullet"
end
```

**File:** `config/environments/development.rb`

```ruby
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true         # JS popup in browser
  Bullet.bullet_logger = true
  Bullet.rails_logger = true
end
```

**File:** `config/environments/test.rb`

```ruby
config.after_initialize do
  Bullet.enable = true
  Bullet.raise = true  # Fail tests on N+1
end
```

### 1b. Strict loading in development

**File:** `config/environments/development.rb`

```ruby
config.active_record.strict_loading_by_default = true
```

This raises `ActiveRecord::StrictLoadingViolationError` whenever a
lazy-loaded association is accessed without `includes`. Forces
developers to eager load in the controller.

**Risk:** May surface existing N+1s that need `includes` added.
Run the test suite after enabling and fix any violations.

---

## Step 2 — Add `includes` to Controllers with N+1 Risk

Based on audit, these controllers load collections that render
associations in views:

| Controller | Action | Missing includes |
|-----------|--------|-----------------|
| `ListingsController` | `index` | `:photos_attachments`, `:agents` (if rendered in cards) |
| `AdsController` | `index` | `:adable` (delegated type) |
| `PlaylistsController` | `show` | `playlist_ads: { ad: :adable }` |
| `ScreensController` | `index` | `site`, `active_player_assignment: :player` |
| `QrCodesController` | `index` | `:destination_record` (polymorphic) |
| `LeadsController` | `index` | Already has includes — verify |

Add `includes` to each index/show action that renders associations.
Bullet will flag any we miss.

---

## Step 3 — Route `:only` Cleanup

Audit `config/routes.rb` for resources generating unused routes.

**Method:** Run `make routes` and cross-reference with controller
actions. Any route with no corresponding action gets `:only`.

Expected changes:
- Admin resources may generate all 7 routes when Administrate only
  uses index/show — but Administrate handles this internally, skip
- App resources are mostly correct already (`:only` used on nested
  resources)
- Verify no orphaned routes exist

---

## Step 4 — I18n Flash Messages

Convert remaining hardcoded flash strings to `t(".success")` pattern.

**Method:** Grep for `notice: "` and `alert: "` in controllers,
replace with I18n keys.

```ruby
# Before
redirect_to @listing, notice: "Listing created."

# After
redirect_to @listing, notice: t(".success")
```

Add corresponding keys to `config/locales/en.yml` under the
controller namespace:

```yaml
en:
  app:
    listings:
      create:
        success: "Listing created."
```

Some controllers already use `t(".success")` — standardize the rest.

---

## Step 5 — DashboardPresenter

**File:** `app/presenters/dashboard_presenter.rb`

Extract ~8 inline queries from `App::DashboardController#show`:

```ruby
class DashboardPresenter
  def initialize(account:, period: 30.days)
    @account = account
    @period = period
  end

  def screens_online
    @account.screens.joins(active_player_assignment: :player)
            .where("players.last_heartbeat_at > ?", 2.minutes.ago)
            .count
  end

  def impressions_this_month
    # ...
  end

  def leads_this_month
    # ...
  end

  def chart_data
    # ... group_by_day queries
  end
end
```

Controller becomes:

```ruby
def show
  @presenter = DashboardPresenter.new(account: Current.account)
end
```

View accesses `@presenter.screens_online`, `@presenter.chart_data`,
etc.

---

## Step 6 — BrandAd Architecture Review

**Not a code change — a design decision.**

BrandAd is a delegated type that adds zero fields. It exists only
to satisfy the `adable` polymorphism. Options:

1. **Keep as-is** — it works, it's just empty
2. **Remove delegated type** — make "brand" a direct Ad type via
   an `ad_type` enum, no adable model
3. **Merge fields** — if brand ads ever get custom fields (sponsor
   logo, CTA URL), the delegated type is justified

**Recommendation:** Defer. It's not broken, and the Ads::BaseController
inheritance handles it cleanly. Revisit when brand ads gain features.

---

## Build Order

```
1. Add Bullet gem + strict loading config
2. Run test suite — fix N+1 violations (add includes)
3. COMMIT

4. Route :only cleanup
5. COMMIT

6. I18n flash messages
7. COMMIT

8. DashboardPresenter
9. COMMIT
```

---

## Verification

1. `make test` — green, no Bullet violations
2. `make lint` — clean
3. Development: Bullet alerts on N+1 in browser
4. All flash messages use I18n keys
5. Dashboard controller is < 10 lines
6. `make routes` — no orphaned routes

---

## Expected Post-Completion Score

| Category | Current | Target |
|----------|:-------:|:------:|
| Performance | 3 | 5 |
| Everything else | 4-5 | 5 |
| **Overall** | **4.5** | **5.0** |
