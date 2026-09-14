# Plan: SMS Keyword Lead Capture

**Created:** 2026-09-14
**Status:** Draft
**Branch:** `sms-lead-capture`

## Problem

QR codes are the only lead capture channel from the kiosk. Not
everyone wants to scan a QR code — some visitors prefer texting.
SMS keywords are a universal fallback: any phone, no camera needed,
no app required.

## How It Works

1. Kiosk displays: **"Text OPEN to (212) 555-1234"**
2. Visitor texts the keyword from their phone
3. System auto-replies with a link to the Go page for that listing
4. Visitor opens the link, browses, fills out the lead form
5. Lead is captured with the phone number as attribution

The keyword is tied to a listing (or screen content). The inbound
number is a shared Twilio number for the account.

## Design

### Models

**`SmsKeyword`** — maps a keyword to a destination.

```
keyword     : string (unique per account, e.g. "OPEN", "350FIFTH")
account_id  : references
destination : polymorphic (Listing, Agent, Experience)
active      : boolean
```

Or simpler: skip a dedicated model and use the QR code's existing
`token` as the keyword. "Text ABC123 to (212) 555-1234" — same
token, different channel. This avoids a new model entirely.

**Decision needed:** Dedicated keywords vs reuse QR tokens.

- **QR tokens** — Already unique, already tied to destinations. No
  new model. But tokens look like "aB3x_9kQ" — not memorable.
- **Dedicated keywords** — "OPEN", "350FIFTH", "LISTING42". Memorable,
  but needs a new model and uniqueness management.
- **Hybrid** — QR tokens always work, but accounts can optionally
  set a human-readable keyword alias. Alias is a column on QrCode.

### Twilio Integration

- **Inbound number** — One Twilio number per account, or one shared
  number with account routing via keyword lookup.
- **Webhook** — Twilio POSTs to `/api/sms/inbound` on each message.
- **Auto-reply** — Respond with the Go page URL.
- **Opt-out** — Handle STOP/HELP per Twilio compliance.

### Controller

```
POST /api/sms/inbound  (Twilio webhook)
  → Parse From, Body (keyword)
  → Look up keyword → resolve destination URL
  → Reply with TwiML: "View this listing: [URL]"
  → Optionally create a lead from the phone number
```

### Analytics

Fire `Analytics::Events::SmsReceived` governed event:
- `qr_code_id` (or keyword_id)
- `phone_number` (hashed for privacy)
- `destination_url`

### Kiosk Display

Add SMS CTA to the ad layouts and experience kiosk, alongside the
QR code. Styled consistently:

```
┌────────────┐
│   QR CODE  │  Text OPEN to
│            │  (212) 555-1234
└────────────┘
```

### Account Setup

- Twilio credentials stored in Rails credentials per environment
- Account-level config: Twilio phone number (or shared)
- Admin UI to manage keywords (if dedicated model)

## Open Questions

1. **One number per account vs shared?** Shared is simpler (one
   Twilio number, keyword routing). Per-account is cleaner but
   costs $1/mo per number.

2. **Keyword model vs QR token reuse?** QR tokens are ugly for SMS.
   A `keyword` column on QrCode might be the sweet spot.

3. **Lead from phone number?** When someone texts, we have their
   phone number. Create a lead immediately (name: "SMS Lead",
   phone: number) or just send the link and let them fill out
   the form?

4. **Compliance** — Twilio requires opt-in language and STOP
   handling. Need to confirm messaging use case with Twilio
   (likely "Notifications" or "Marketing" campaign type).

## Execution

### Step 1 — Twilio setup
- Add `twilio-ruby` gem
- Store credentials in Rails credentials
- Create Twilio messaging service + phone number

### Step 2 — Keyword column on QrCode (TDD)
- **RED:** Model spec for `keyword` column, uniqueness within account
- **GREEN:** Migration adding `keyword` to `qr_codes`, validation

### Step 3 — Inbound SMS controller (TDD)
- **RED:** Request spec for `POST /api/sms/inbound` — keyword lookup, TwiML response
- **GREEN:** `Api::Sms::InboundController` with Twilio request validation

### Step 4 — Auto-reply with Go page URL
- Resolve keyword → QrCode → destination → Go page URL
- Reply via TwiML
- Fire `sms.received` governed event

### Step 5 — Kiosk SMS CTA display
- Add SMS CTA partial alongside QR code in ad layouts
- Display keyword + phone number

### Step 6 — Admin/app keyword management
- UI to set keyword on QR code edit page
- Auto-generate a suggestion from the listing address

### Step 7 — Ship
- `make lint`, `make test`
- Twilio webhook URL configuration
- Push, create PR

## Dependencies

- Twilio account + phone number
- Twilio compliance review for messaging use case

## Out of Scope

- Two-way conversation (bot flow)
- MMS (sending photos via text)
- Per-account Twilio numbers (start with shared)
