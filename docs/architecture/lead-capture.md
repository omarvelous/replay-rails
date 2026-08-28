# Lead Capture

The lead capture pipeline connects QR code scans on physical signage to contact form submissions in the app.

## Pipeline

```
Screen displays ad with QR code
  → Passerby scans QR code
    → GET /s/:token (ScansController)
      → QrScan created with attribution (ad, screen, playlist)
        → Redirect to Go:: landing page (listing or agent)
          → Visitor fills out contact form
            → POST /go/leads (Go::LeadsController)
              → Lead created + LeadAgent assigned
                → LeadMailer.new_lead sent to agent
```

## Attribution chain

Every lead carries full attribution back to the physical display:

| Field | Source | Description |
|-------|--------|-------------|
| `qr_scan.ad_id` | URL param `a` | Which ad was showing |
| `qr_scan.screen_id` | URL param `s` | Which screen it was on |
| `qr_scan.playlist_id` | URL param `p` (stored in context jsonb) | Which playlist was playing |
| `qr_scan.ip_address` | Request | Scanner's IP |
| `qr_scan.user_agent` | Request | Scanner's browser |
| `lead.listing_id` | Landing page | Which listing they inquired about |
| `lead.qr_scan_id` | Hidden form field | Links back to the scan |

The QR code URL on each ad embeds the attribution params:

```
/s/ABC123?a=42&s=7&p=3
```

## QR scan flow

`ScansController#show` (`GET /s/:token`, any subdomain, no auth):

1. Find `QrCode` by token (404 if not found or inactive)
2. Create `QrScan` with ad_id, screen_id, playlist context, IP, user agent
3. Redirect based on destination:
   - `destination_url` → external redirect
   - `destination_record` → `Go::` landing page with `scan_id` param
   - Neither → app root

## Qualified scans

`QrScan.qualified` scope filters to scans where both `ad_id` and `screen_id` are present — meaning the scan came from an active screen displaying a known ad, not from a direct URL share or test.

## Landing pages

The `Go::` controllers render public landing pages on the marketing subdomain:

- `Go::ListingsController#show` — property details with lead form
- `Go::AgentsController#show` — agent profile with lead form

Both pass `scan_id` as a hidden field in the form so the resulting lead links back to the scan.

## Lead creation

`Go::LeadsController#create` (unauthenticated, rate-limited):

1. **Honeypot check** — if `website` field is populated, silently discard (bot)
2. **Resolve context** — find listing, agent (falls back to listing's primary agent), account
3. **Create lead** — with `qr_scan`, `listing`, `account`, plus contact details (name, email, phone, message, lead_type)
4. **Assign agent** — create `LeadAgent` record linking lead to agent
5. **Notify** — enqueue `LeadMailer.new_lead` to email the agent

## Lead model

| Field | Description |
|-------|-------------|
| `status` | `new`, `contacted`, `qualified`, `closed` |
| `lead_type` | `buyer_inquiry`, `renter_inquiry`, `seller_inquiry`, `open_house_rsvp`, `general_inquiry`, `agent_recruitment` |
| `listing_id` | Optional — which property they inquired about |
| `qr_scan_id` | Optional — which scan originated the lead |

## Agent assignment

`LeadAgent` is a join model between Lead and Agent. It supports reassignment — creating a new `LeadAgent` record preserves the assignment history via `created_at` timestamps. The most recent assignment is the current agent.

## Rate limiting

Public lead submission is protected by:

- **Rack::Attack** — 10 submissions per IP per hour
- **Honeypot field** — hidden `website` field catches bots
