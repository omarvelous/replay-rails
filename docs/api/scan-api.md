# Scan API

The scan endpoint records QR code interactions and redirects users to landing pages.

## Endpoint

```
GET /s/:token
```

**Subdomain:** Any (route is defined outside subdomain constraints).
**Authentication:** None required.

## Parameters

| Param | Source | Description |
|-------|--------|-------------|
| `:token` | URL path | QR code token |
| `a` | Query string | Ad ID (which ad was displaying) |
| `s` | Query string | Screen ID (which screen it was on) |
| `p` | Query string | Playlist ID (which playlist was playing) |

Example URL embedded in a QR code on a screen:

```
https://replay.com/s/xK9mB2pQ?a=42&s=7&p=3
```

## Flow

1. **Find QR code** — look up by token where `active: true`. Return 404 if not found.

2. **Record scan** — create a `QrScan` with:
   - `qr_code_id` — the QR code
   - `account_id` — from the QR code
   - `ad_id` — from `params[:a]`
   - `screen_id` — from `params[:s]`
   - `context` — jsonb with `{ playlist_id: params[:p] }`
   - `ip_address` — from request
   - `user_agent` — from request

3. **Redirect** (in priority order):
   - If `qr_code.destination_url` is set → redirect to external URL
   - If `qr_code.destination_record` is set → redirect to `Go::` landing page with `scan_id` appended
   - Otherwise → redirect to app root

## Redirect examples

| Destination | Redirects to |
|------------|-------------|
| Listing #5 | `replay.com/go/listings/5?scan_id=123` |
| Agent #3 | `replay.com/go/agents/3?scan_id=123` |
| External URL | `https://example.com/open-house` |

The `scan_id` parameter is passed to the landing page so the lead form can link the resulting lead back to the scan for attribution.

## Qualified scans

Not every scan comes from a live screen. People share QR code URLs, test them in development, or scan from printed materials.

`QrScan.qualified` scope: both `ad_id` AND `screen_id` must be present. This filters to scans that originated from an active screen displaying a known ad.

Non-qualified scans are still recorded but excluded from analytics dashboards and conversion metrics.

## Rate limiting

60 scans per IP per minute via Rack::Attack. Prevents abuse from automated scanning.
