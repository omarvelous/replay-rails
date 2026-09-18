# Plan: Simplify Ahoy Account Context

**Created:** 2026-09-18
**Status:** Draft
**Branch:** TBD

## Problem

Account context on Ahoy events is maintained through a custom
`Ahoy::Store` that injects `account_id` into a custom column on
`ahoy_visits` and `ahoy_events`. This required:

- Custom Store overrides (`track_visit`, `track_event`)
- Custom `account_id` columns + indexes on both Ahoy tables
- Making `current_account` a public on-demand method on the
  Authentication concern (lazy `resume_session` pattern)
- `indifferent_access` hack for player events that arrive without
  a controller `current_account`
- All of this because Ahoy's Store runs outside the normal
  controller callback chain

Meanwhile, the JS already sends `account_pid` in every analytics
event. It lands in the jsonb properties unvalidated.

## Design

Move account context entirely into event properties via
`account_pid` on `Analytics::Events::Base`. Remove the custom
Store and custom columns.

### What changes

**Add to Base:**
```ruby
class Base
  attribute :account_pid, :string
end
```

Every event PORO inherits it. JS already sends it. The GIN index
on `ahoy_events.properties` covers queries.

**Remove custom Ahoy::Store:**
```ruby
# Before
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:account_id] = controller&.try(:current_account)&.id
    super
  end
  def track_event(data)
    props = (data[:properties] || {}).with_indifferent_access
    data[:account_id] = controller&.try(:current_account)&.id || props[:account_id]
    super
  end
end

# After
# No custom Store needed — use Ahoy::DatabaseStore defaults
```

**Remove custom columns:**
Migration dropping `account_id` from `ahoy_visits` and `ahoy_events`.

**Simplify Authentication concern:**
`current_account` no longer needs to be a public on-demand method
with lazy `resume_session`. It can go back to being a standard
helper set by `before_action`.

**Update queries:**
Dashboard, rollup job, and controller queries change from
`Ahoy::Event.where(account_id: ...)` to
`where_properties(account_pid: ...)`.

### What stays the same

- JS analytics wrapper sends `account_pid` (already does)
- Ahoy visit/event tracking works as normal
- GIN index on properties handles jsonb queries
- `Ahoy.exclude_method` for admin subdomain stays

## Execution

### Step 1 — Add account_pid to Base
- Add `attribute :account_pid, :string` to `Analytics::Events::Base`
- Add `account_pid` to JS catalog for all events
- Existing JS already sends it — just govern it

### Step 2 — Update queries
- Dashboard controller: `account_id` → `where_properties(account_pid:)`
- Rollup job: same
- Any other `Ahoy::Event.where(account_id:)` queries

### Step 3 — Remove custom Ahoy::Store
- Replace with default `Ahoy::DatabaseStore` or remove file
- Remove `indifferent_access` hack

### Step 4 — Migration: drop account_id columns
- Remove `account_id` from `ahoy_visits` and `ahoy_events`
- Remove associated indexes

### Step 5 — Simplify Authentication concern
- `current_account` can become a simple helper, no longer
  needs lazy `resume_session` pattern for Ahoy compatibility

### Step 6 — Update seeds
- Remove `account_id` from seeded Ahoy events/visits

### Step 7 — Ship
- Update docs, CLAUDE.md
- `make lint`, `make test`
- Push, create PR

## Related: Add listing_pid to ContentImpressed

The `ContentImpressed` event should carry `listing_pid` directly.
Currently the listing impression count query in `ListingsController`
works backwards from ad IDs → event properties, which is slow and
fragile. With `listing_pid` as a property, the query becomes
`ContentImpressed.where_properties(listing_pid: @listing.public_id).count`.

The listing is known at impression time (via `ad.adable.listing`).
Add it to the JS event emission alongside `ad_pid`.

## Trade-offs

- Jsonb property queries are slightly slower than integer column
  queries. Mitigated by GIN index. Negligible at current scale.
- Rollups that group by account would use `group_prop(:account_pid)`
  instead of `group(:account_id)`.
- Historical events already have `account_id` in the column but
  not `account_pid` in properties. May need a backfill or accept
  that pre-migration events lack the property.
