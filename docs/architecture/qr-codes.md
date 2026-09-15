# QR Codes

QR codes connect physical signage to digital interactions. Each listing and agent gets a QR code that, when scanned, fires an analytics event and redirects to a landing page.

## Model

### QrCode

```ruby
belongs_to :account
belongs_to :destination_record, polymorphic: true, optional: true
```

- `token` — auto-generated unique identifier, used in the scan URL
- `public_id` — UUID via `PublicIdentifiable`, used in analytics events
- `destination_record` — polymorphic link to a Listing or Agent
- `destination_url` — optional external URL override
- `active` — boolean, inactive codes return 404

## Scan tracking

Scans are tracked as `qr.scanned` Ahoy events via the `Analytics::Events::QrScanned` governed event PORO. Event properties carry full attribution context:

```ruby
Analytics::Events::QrScanned.create(
  qr_code_pid: qr.public_id,
  destination_url: destination,
  ad_pid: params[:a].presence,
  screen_pid: params[:s].presence,
  screen_content_pid: params[:sc].presence,
  request: request
)
```

### Querying scans

`QrCode` provides convenience methods that delegate to the governed event PORO:

```ruby
qr.scan_events           # Ahoy::Event relation for this QR code
qr.scan_count             # count
qr.scan_events.qualified  # events with both ad_pid and screen_pid
```

The `qualified` scope is defined in `QrScanned::Scopes` and mixed into the relation via `extending`, so it chains naturally with `where_properties`.

## Scan URL format

```
/s/:token?a=<ad_pid>&s=<screen_pid>&sc=<screen_content_pid>
```

The `/s/:token` route is public (any subdomain, no auth). The player embeds attribution params when rendering QR codes in ad slides via the `qr_scan_full_url` helper.

## QR code rendering

QR codes are rendered as inline SVGs in ad layout partials via the `_qr_badge` shared partial. The `rqrcode` gem generates the SVG matrix. The scan URL includes the current ad, screen, and screen content context.

## Rate limiting

Scan endpoints are protected by Rack::Attack: 60 scans per IP per minute.
