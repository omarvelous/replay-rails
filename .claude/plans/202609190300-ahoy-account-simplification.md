# Plan v2: Simplify Ahoy Account Context

**Created:** 2026-09-18 (v1), **Updated:** 2026-09-19 (v2)
**Status:** Draft

## Problem

Account context on Ahoy events is maintained through a custom
`Ahoy::Store` that injects `account_id` into custom columns on
`ahoy_visits` and `ahoy_events`. This required:

- Custom Store overrides (`track_visit`, `track_event`)
- Custom `account_id` columns + indexes on both Ahoy tables
- `indifferent_access` hack for player events without controller
- Making `current_account` a public on-demand method for Ahoy

Meanwhile, the JS already sends `account_pid` in every event via
Stimulus controllers. It lands in the jsonb `properties` column
but isn't governed by the event POROs.

No historical data concerns — clean swap.

## Solution

Move account context entirely into event properties via
`account_pid` on `Analytics::Events::Base`. Remove the custom
Store, custom columns, and the hacks they required.

---

## Step 1 — Add `account_pid` to Analytics::Events::Base

**File:** `app/models/analytics/events/base.rb`

```ruby
attribute :account_pid, :string
```

Every event PORO inherits it. JS already sends it. Just govern it.

**File:** `app/javascript/analytics/catalog.js`

Add `account_pid: { required: true }` to every event that sends it
(all player and kiosk events). QrScanned is server-side — add
`account_pid` there too (set from `qr.account.public_id`).

---

## Step 2 — Update queries

All queries that filter by `account_id` column change to filter
by `account_pid` in jsonb properties.

| File | Before | After |
|------|--------|-------|
| `app/presenters/dashboard_presenter.rb` | `Ahoy::Event.where(account_id: account.id)` | `Ahoy::Event.where_properties(account_pid: account.public_id)` |
| `app/jobs/analytics_rollup_job.rb` | `.group(:account_id)` | Group by `account_pid` from properties |
| `app/controllers/scans_controller.rb` | No `account_pid` on QrScanned | Add `account_pid: qr.account.public_id` |

---

## Step 3 — Remove custom Ahoy::Store

**File:** `config/initializers/ahoy.rb`

Remove the custom `Ahoy::Store` class. Keep config only:

```ruby
Ahoy.api = true
Ahoy.visit_duration = 4.hours
Ahoy.cookie_domain = :all
Ahoy.mask_ips = true
Ahoy.geocode = false
Ahoy.server_side_visits = :when_needed

Ahoy.exclude_method = ->(controller, request) {
  request&.subdomain == "admin"
}
```

---

## Step 4 — Migration: drop `account_id` columns

```ruby
class RemoveAccountIdFromAhoyTables < ActiveRecord::Migration[8.1]
  def change
    remove_column :ahoy_visits, :account_id, :bigint
    remove_column :ahoy_events, :account_id, :bigint
  end
end
```

---

## Step 5 — Update ScansController + QrScanned event

Add `account_pid` to server-side QrScanned event:

```ruby
Analytics::Events::QrScanned.create(
  qr_code_pid: qr.public_id,
  account_pid: qr.account&.public_id,
  ...
)
```

---

## Step 6 — Update docs

Remove "Account on events — Set via Ahoy::Store" from CLAUDE.md.
Document that `account_pid` flows through event properties.
Update `docs/dev/event-catalog.md`.

---

## Build Order

```
1. Add account_pid to Base + JS catalog
2. COMMIT

3. Update DashboardPresenter + rollup job + ScansController
4. COMMIT

5. Remove custom Ahoy::Store
6. Migration: drop account_id columns
7. COMMIT

8. Update docs
9. COMMIT
```

---

## Verification

1. `make test` — green
2. Dashboard shows correct metrics
3. Player impression → event has `account_pid` in properties
4. QR scan → event has `account_pid` in properties
5. No `account_id` column in Ahoy tables
6. No custom Ahoy::Store class

---

## Files Changed

| File | Change |
|------|--------|
| `app/models/analytics/events/base.rb` | Add `account_pid` attribute |
| `app/javascript/analytics/catalog.js` | Add `account_pid` to all events |
| `app/presenters/dashboard_presenter.rb` | `where(account_id:)` → `where_properties(account_pid:)` |
| `app/jobs/analytics_rollup_job.rb` | Update grouping queries |
| `app/controllers/scans_controller.rb` | Add `account_pid` to QrScanned |
| `config/initializers/ahoy.rb` | Remove custom Store class |
| Migration | Drop `account_id` from ahoy tables |
| `CLAUDE.md` | Remove Store docs |
| `docs/dev/event-catalog.md` | Update account association docs |
