# Lead Capture

The lead capture pipeline connects QR code scans on physical signage to contact form submissions.

## Pipeline

```
Screen displays ad with QR code
  → Passerby scans QR code
    → GET /s/:token (ScansController)
      → qr.scanned Ahoy event fired with attribution
        → Redirect to Go:: landing page (listing or agent)
          → Visitor fills out contact form
            → POST /go/leads (Go::LeadsController)
              → Lead created + LeadAgent assigned
                → LeadMailer.new_lead sent to agent
```

## Attribution

Attribution flows through two channels:

**Event-level** — The `qr.scanned` Ahoy event records which ad, screen, and screen content were active when the QR code was scanned. Stored as event properties (`ad_pid`, `screen_pid`, `screen_content_pid`).

**Visit-level** — Leads use `visitable :ahoy_visit`, which auto-sets `ahoy_visit_id` on create. The lead's Ahoy visit contains the `qr.scanned` event, linking it back to the physical context. The lead show page reads attribution from the visit's `qr.scanned` event properties.

## Scan flow

`ScansController#show` (`GET /s/:token`, any subdomain, no auth):

1. Find `QrCode` by token (404 if not found or inactive)
2. Determine destination URL (external URL → Go page → app root fallback)
3. Fire `Analytics::Events::QrScanned` with attribution params
4. Redirect to destination

## Qualified scans

`QrScanned.qualified` filters to events where both `ad_pid` and `screen_pid` are present — scans from active screens displaying a known ad, not direct URL shares or test scans.

## Landing pages

The `Go::` controllers render public landing pages on the marketing subdomain:

- `Go::ListingsController#show` — property details with photo gallery, agent card, lead form
- `Go::AgentsController#show` — agent profile with bio, active listings, lead form

## Lead creation

`Go::LeadsController#create` (unauthenticated, rate-limited):

1. **Honeypot check** — if `website` field is populated, silently discard (bot)
2. **Resolve context** — find listing, agent (falls back to listing's primary agent), account
3. **Create lead** — with `listing`, `account`, plus contact details (name, email, phone, message, lead_type)
4. **Assign agent** — create `LeadAgent` record linking lead to agent
5. **Notify** — enqueue `LeadMailer.new_lead` to email the agent

## Lead model

| Field | Description |
|-------|-------------|
| `status` | `new`, `contacted`, `qualified`, `closed` |
| `lead_type` | `buyer_inquiry`, `renter_inquiry`, `seller_inquiry`, `open_house_rsvp`, `general_inquiry`, `agent_recruitment` |
| `listing_id` | Optional — which property they inquired about |
| `ahoy_visit_id` | Optional — the Ahoy visit that created this lead (carries scan attribution) |

## Agent assignment

`LeadAgent` is a join model between Lead and Agent. It supports reassignment — creating a new `LeadAgent` record preserves history via `created_at` timestamps. The most recent assignment is the current agent.

## Rate limiting

Public lead submission is protected by:

- **Rack::Attack** — 10 submissions per IP per hour
- **Honeypot field** — hidden `website` field catches bots
