# Analytics

Unified event tracking via Ahoy with governed event POROs for type safety and query scopes.

## Stack

| Component | Purpose |
|-----------|---------|
| Ahoy | Visits + events across all subdomains |
| Governed event POROs | `Analytics::Events::*` — typed attributes, validations, Ahoy emission |
| JS analytics wrapper | `app/javascript/analytics/` — mirrors Ruby POROs, validates before `ahoy.track()` |
| ahoy-email | `has_history` + `track_clicks` on mailers for open/click tracking |
| Rollups | `AnalyticsRollupJob` aggregates daily metrics per account via Solid Queue |

## Ahoy configuration

- `Ahoy.visit_duration = 4.hours`
- `Ahoy.cookie_domain = :all` — cookies shared across subdomains
- `Ahoy.server_side_visits = :when_needed` — creates server-side visits for API/scan requests
- `Ahoy.mask_ips = true`
- `Ahoy.exclude_method` — excludes admin subdomain from tracking

### Ahoy::Store

Custom store enriches visits and events with `account_id`:

```ruby
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
```

App controllers set account from `Current.account`. Player events fall back to `account_id` in event properties.

## Governed events

ActiveModel POROs in `app/models/analytics/events/`. Each event has typed attributes and validations. Create with:

```ruby
Analytics::Events::ContentImpressed.create(
  ad_pid: ad.public_id,
  screen_pid: screen.public_id,
  screen_content_pid: content.public_id,
  playlist_pid: playlist.public_id,
  position: 1,
  duration: 10
)
```

Invalid events return false from `.create` and do not fire. See `docs/dev/event-catalog.md` for the full event list.

### Write path

`Base#emit` resolves the Ahoy tracker:
1. If `request` is present → uses `controller.ahoy` (inherits visit context)
2. Otherwise → creates a bare `Ahoy::Tracker` (server-side visit)

### Query path

`Base` provides class methods that return `Ahoy::Event` relations:

```ruby
ContentImpressed.events                          # all content.impressed events
ContentImpressed.where_properties(ad_pid: "...")  # jsonb @> containment filter
```

`where_properties` delegates to Ahoy's built-in `Ahoy::QueryMethods#where_properties` which is database-adapter-aware.

### Chainable scopes via extending

Event POROs can define a `Scopes` module for event-specific scopes:

```ruby
class QrScanned < Base
  module Scopes
    def qualified
      where("properties ? 'ad_pid' AND properties ? 'screen_pid'")
    end
  end
end
```

`Base.events` auto-extends the relation with `Scopes` when defined:

```ruby
QrScanned.events.qualified
QrScanned.where_properties(qr_code_pid: "...").qualified
```

## JS analytics wrapper

`app/javascript/analytics/` mirrors the Ruby POROs. `Analytics.create("event.name", { ... })` validates required properties before calling `window.ahoy.track()`.

## Page views

`ahoy.trackView()` fires on initial load and `turbo:load` events, tracking page views across all subdomains (except admin).

## Visit attribution

`Lead` and `Inquiry` use `visitable :ahoy_visit`. Ahoy auto-sets `ahoy_visit_id` on create, linking the record to the session. The visit carries the `qr.scanned` event for lead attribution.

## Rollups

`AnalyticsRollupJob` runs daily via Solid Queue and aggregates:
- Impressions per account (from `content.impressed` events)
- Kiosk sessions per account (from `interaction.started` events)
- QR scans per account (from `qr.scanned` events)
- Leads per account (from `leads` table)

Results stored in the `rollups` table via the rollups gem.
