# QR Codes

QR codes connect physical signage to digital interactions. Each listing and agent gets a QR code that, when scanned, records attribution data and redirects to a landing page.

## Models

### QrCode

```ruby
belongs_to :account
belongs_to :destination_record, polymorphic: true, optional: true
has_many :scans, class_name: "QrScan"
```

- `token` — auto-generated unique identifier, used in the scan URL
- `destination_record` — polymorphic link to a Listing or Agent
- `destination_url` — optional external URL override
- `active` — boolean, inactive codes return 404

### QrScan

```ruby
belongs_to :qr_code
belongs_to :account
belongs_to :ad, optional: true
belongs_to :screen, optional: true
has_many :leads
```

- `ad_id`, `screen_id` — attribution from URL params
- `context` — jsonb store for `playlist_id`, `slide_position`
- `ip_address`, `user_agent` — scanner's browser info

## Scan URL format

```
/s/:token?a=<ad_id>&s=<screen_id>&p=<playlist_id>
```

The `/s/:token` route is public (any subdomain, no auth). The player embeds the attribution params when rendering QR codes in ad slides.

## Scan flow

1. `ScansController#show` finds the QR code by token
2. Creates a `QrScan` record with all attribution data
3. Redirects to the destination:
   - `destination_url` → external redirect
   - `destination_record` → `Go::` landing page with `scan_id` appended
   - Neither → app root fallback

## Qualified scans

The `QrScan.qualified` scope filters to scans where both `ad_id` AND `screen_id` are present:

```ruby
scope :qualified, -> { where.not(ad_id: nil).where.not(screen_id: nil) }
```

This distinguishes scans from active signage (someone scanned a QR code on a real screen) from direct URL shares, test scans, or bookmarked links.

Qualified scans are used for:
- Dashboard funnel metrics
- Conversion rate calculations (scans → leads)
- Per-screen and per-ad performance

## QR code rendering

QR codes are rendered as inline SVGs in ad layout partials via the `_qr_badge` shared partial. The `rqrcode` gem generates the SVG matrix. The scan URL is embedded with the current ad, screen, and playlist context.

## Rate limiting

Scan endpoints are protected by Rack::Attack: 60 scans per IP per minute.
