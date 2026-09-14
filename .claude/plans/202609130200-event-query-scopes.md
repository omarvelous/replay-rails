# Plan: Governed Event Query Scopes

**Created:** 2026-09-13
**Status:** Draft
**Branch:** `event-query-scopes`

## Problem

Raw `Ahoy::Event.where(name: "qr.scanned")` queries are scattered across controllers, views, jobs, and models. The governed event POROs already define the event name and properties — they should also own the query interface. This eliminates string duplication, centralizes jsonb query patterns, and makes event queries testable and composable.

## Current State

14 raw `Ahoy::Event.where(name: ...)` calls across:

| Location | Event | What it does |
|----------|-------|-------------|
| `QrCode#scan_events` | `qr.scanned` | Events for a specific QR code |
| `QrCode#qualified_scan_events` | `qr.scanned` | Events with ad_id + screen_id |
| `App::AdsController#show` | `qr.scanned` | Scan count for a specific ad |
| `App::AdsController#show` | `content.impressed` | Impression count for a specific ad |
| `App::ListingsController#show` | `content.impressed` | Impression count for a specific listing |
| `Admin::DashboardController#show` | `content.impressed` | Total + today impression counts |
| `Admin::DashboardController#show` | `qr.scanned` | Total + today scan counts (qualified) |
| `admin/dashboard/show.html.erb` | `content.impressed` | 30-day chart series |
| `admin/dashboard/show.html.erb` | `qr.scanned` | 30-day chart series (qualified) |
| `AnalyticsRollupJob` | `content.impressed` | Daily rollup by account |
| `AnalyticsRollupJob` | `interaction.started` | Daily rollup by account |
| `AnalyticsRollupJob` | `qr.scanned` | Daily rollup by account |
| `db/seeds.rb` | `qr.scanned` | Guard check for idempotent seeding |

## Target State

```ruby
# Instead of:
Ahoy::Event.where(name: "qr.scanned")
  .where("properties @> ?", { qr_code_id: id }.to_json)

# Write:
Analytics::Events::QrScanned.events
  .where_properties(qr_code_id: id)

# Named scopes on individual POROs:
Analytics::Events::QrScanned.qualified  # ad_id + screen_id present

# Convenience methods:
Analytics::Events::ContentImpressed.events.where_properties(ad_id: @ad.id).count
```

## Design

### `Analytics::Events::Base` additions

```ruby
class Base
  # Returns Ahoy::Event scope filtered to this event name
  def self.events
    Ahoy::Event.where(name: event_name)
  end

  # Filters by jsonb properties using @> containment
  def self.where_properties(**props)
    events.where("properties @> ?", props.to_json)
  end
end
```

### `Analytics::Events::QrScanned` additions

```ruby
class QrScanned < Base
  def self.qualified
    events.where("properties ? 'ad_id' AND properties ? 'screen_id'")
  end
end
```

### `QrCode` model simplification

```ruby
def scan_events
  Analytics::Events::QrScanned.where_properties(qr_code_id: id)
end

def scan_count
  scan_events.count
end

# Remove qualified_scan_events — callers chain directly:
#   qr.scan_events.qualified
```

## Execution

### Step 1 — Base query interface (TDD)
- **RED:** Spec `Base.events`, `Base.where_properties` on a test subclass
- **GREEN:** Implement on `Base`

### Step 2 — QrScanned.qualified scope (TDD)
- **RED:** Spec `QrScanned.qualified` returns events with both ad_id and screen_id
- **GREEN:** Implement on `QrScanned`

### Step 3 — Replace QrCode model queries
- Update `QrCode#scan_events`, `#scan_count`, `#qualified_scan_events` to use PORO scopes
- Existing specs should still pass (no new specs needed)

### Step 4 — Replace controller and view queries
- Update `App::AdsController`, `App::ListingsController`, `Admin::DashboardController`
- Update `admin/dashboard/show.html.erb` chart queries
- Existing specs should still pass

### Step 5 — Replace job queries
- Update `AnalyticsRollupJob`
- Existing specs should still pass

### Step 6 — Replace seed guard
- Update `db/seeds.rb` guard to use PORO scope

### Step 7 — Cleanup and ship
- `make lint`, `make test`
- Push, create PR

## Implementation Notes

### Ahoy already provides `where_properties`

`Ahoy::QueryMethods` (included in `Ahoy::Event`) provides `where_properties`, `where_props`, `where_event`, and `group_prop` — all database-adapter-aware and chainable on relations. Our `Base.where_properties` delegates to Ahoy's implementation rather than reimplementing the jsonb query.

### Extending for chainable scopes

Event-specific scopes (e.g., `QrScanned::Scopes#qualified`) are mixed into the relation via `ActiveRecord::Relation#extending`. `Base.events` checks for a `Scopes` constant on the subclass and extends the relation automatically:

```ruby
def self.events
  scope = Ahoy::Event.where(name: event_name)
  scope = scope.extending(self::Scopes) if const_defined?(:Scopes)
  scope
end
```

This makes scopes fully chainable on any relation returned by `events` or `where_properties`:

```ruby
QrScanned.events.qualified
QrScanned.where_properties(qr_code_id: 5).qualified
qr.scan_events.qualified  # scan_events delegates through where_properties
```

## Out of Scope

- Adding query scopes to event POROs that aren't currently queried (ContentLoaded, DeviceConnected, interaction events besides InteractionStarted)
- Moving the Ahoy::Event model itself — it stays as the underlying storage
