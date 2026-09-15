# Scan API

The scan endpoint tracks QR code interactions via Ahoy events and redirects users to landing pages.

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
| `a` | Query string | Ad public ID (which ad was displaying) |
| `s` | Query string | Screen public ID (which screen it was on) |
| `sc` | Query string | Screen content public ID (which content was playing) |

Example URL embedded in a QR code on a screen:

```
https://rply.tv/s/xK9mB2pQ?a=abc123&s=def456&sc=ghi789
```

## Flow

1. **Find QR code** — look up by token where `active: true`. Return 404 if not found or inactive.

2. **Determine destination** (in priority order):
   - If `qr_code.destination_url` is set → use external URL
   - If `qr_code.destination_record` is set → use `Go::` landing page URL
   - Otherwise → app root fallback

3. **Fire governed event** — `Analytics::Events::QrScanned.create` with:
   - `qr_code_pid` — the QR code's public ID
   - `destination_url` — where the visitor is being sent
   - `ad_pid`, `screen_pid`, `screen_content_pid` — attribution from URL params
   - `request` — for Ahoy visit association

4. **Redirect** — send the visitor to the destination URL.

## Redirect examples

| Destination | Redirects to |
|------------|-------------|
| Listing | `replaytv.co/go/listings/abc123` |
| Agent | `replaytv.co/go/agents/def456` |
| External URL | `https://example.com/open-house` |

## Qualified scans

Not every scan comes from a live screen. People share QR code URLs, test them, or scan from printed materials.

`QrScanned.qualified` scope filters to events where both `ad_pid` AND `screen_pid` are present — meaning the scan came from an active screen displaying a known ad.

```ruby
Analytics::Events::QrScanned.events.qualified
```

Non-qualified scans are still recorded but excluded from dashboard metrics.

## Rate limiting

60 scans per IP per minute via Rack::Attack.
