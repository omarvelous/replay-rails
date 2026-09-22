# Analysis: Lead Capture Channels (QR, NFC, SMS)

## Three Channels, Three Behaviors

| Channel | Physical medium | User action | Range | Requires form? | Auto-captures phone? |
|---------|----------------|-------------|-------|:--------------:|:-------------------:|
| **QR** | Printed/displayed code | Point camera, scan | ~3-6 feet | Yes | No |
| **NFC** | Programmed tag/sticker | Tap phone to tag | ~4 inches | Yes | No |
| **SMS** | Displayed number + keyword | Text from anywhere | Unlimited | **No** | **Yes** |

---

## Scenarios by Product Context

### Storefront Window Display

A brokerage window with a screen looping listing ads.
Pedestrians walking by.

| Channel | What's displayed | Visitor action | What they get | What we capture |
|---------|-----------------|---------------|---------------|-----------------|
| **QR** | QR code on the ad (`_qr_badge.html.erb`) | Point camera, scan | Go listing page with lead form | Visit + scan event with ad/screen attribution. Lead only if they fill form. |
| **NFC** | "Tap here" sticker on window glass | Hold phone to glass | Same Go listing page | Same as QR with `channel: nfc`. Must be within inches — works through glass. |
| **SMS** | "Text MAIN123 to 55510" on the ad | Text from anywhere — across the street, from car | Auto-reply with listing URL | **Phone number captured instantly.** Lead without a form. Don't need to visit the page. |

**SMS wins here.** Pedestrian can capture a listing from across the
street without stopping. QR requires walking up. NFC requires
touching the glass.

### Open House Kiosk

Portable touchscreen at a listing showing the experience.
Visitors browsing.

| Channel | What's displayed | Visitor action | What they get | What we capture |
|---------|-----------------|---------------|---------------|-----------------|
| **QR** | QR code on kiosk screen (QR handoff) | Scan the screen | Go experience page on their phone | Scan event with experience/screen attribution. Lead if they fill form. |
| **NFC** | "Tap phone here" on kiosk bezel/stand or table tent | Tap phone to the tag | Same Go experience page | Same as QR. More intimate — visitor must approach. |
| **SMS** | "Text OPEN789 to 55510 for the floor plan" | Text from anywhere in room | Auto-reply with listing URL + floor plan | **Phone number + gated content (floor plan).** |

**All three work.** QR handoff is the default. NFC is premium
touch. SMS captures phone number without a form AND can deliver
gated content (floor plan PDF) directly via text.

### Yard Sign / Drive-By

Yard sign in front of a listing. People driving or walking by.

| Channel | Viable? | Why |
|---------|:-------:|-----|
| **QR** | Marginal | Requires stopping and being close enough to scan |
| **NFC** | No | ~4 inch range. Physically impossible from sidewalk/car. |
| **SMS** | **Yes** | Works from 50 feet away. Only channel for drive-by. |

**SMS is the only viable channel for drive-by.** This is a common
real estate use case — rider signs with "Text HOME456 for info."

### Agent Business Card / Networking

Agent hands out cards at events, meetings, open houses.

| Channel | What's on the card | Recipient action | Feel |
|---------|-------------------|-----------------|------|
| **QR** | QR code | Scan later | Standard |
| **NFC** | NFC-enabled card | Tap phone to card | Premium — "tap my card" |
| **SMS** | "Text SARAH to 55510" | Text the keyword | Works when they find the card later |

**All three work.** NFC has the "wow factor" for in-person.
SMS works asynchronously.

---

## What Each Channel Actually Captures

| Channel | Requires form? | Phone number? | Email? | Full attribution? |
|---------|:--------------:|:------------:|:------:|:-----------------:|
| **QR** | Yes (Go page) | Only if submitted | Only if submitted | Yes (ad, screen, creative) |
| **NFC** | Yes (same page) | Only if submitted | Only if submitted | Yes (same token) |
| **SMS** | **No** | **Yes — automatically** | No | Keyword → destination mapping |

**SMS is the only channel that captures a lead without a form.**
The act of texting IS the lead — you have their phone number the
moment they send the message. QR and NFC get visitors to the Go
page, but they have to fill out the form to become a lead.

This means SMS isn't just another channel — it's a **passive lead
capture mechanism.** Every text is a lead. Every scan/tap is just
a visit until they fill out the form.

---

## Data Model

All three channels flow through the same `QrCode` model (which
is really a "capture point"):

```
QrCode
├── token: "abc123"              → /s/abc123 (QR, NFC, direct link)
├── keyword: "MAIN123"           → SMS "text MAIN123 to 55510"
├── destination_record: listing  → Go listing page
├── creative: ad                 → which ad generated this
├── screen_content: sc           → which screen it was on
└── account: brokerage
```

### URL-based channels (QR + NFC)

Same flow, different `channel` attribute:

```
QR scan  → /s/abc123?via=qr  → ScansController → redirect + event
NFC tap  → /s/abc123?via=nfc → ScansController → redirect + event
```

NFC tags encode the exact same URL as the QR code. No new model,
no new controller. Just a `channel` param that flows into the
analytics event.

### SMS channel

Different flow — async, text-based:

```
User texts "MAIN123" to 55510
  → Twilio webhook → Api::Sms::InboundController
  → Look up QrCode by keyword
  → Create Lead (phone number from sender)
  → Auto-reply with destination URL
  → Fire SmsReceived event
```

SMS needs:
- `keyword` column on QrCode
- Twilio account + phone number
- Webhook controller for inbound messages
- TwiML response generation
- Lead auto-creation from phone number

### Analytics events

```ruby
# QR/NFC — same event, different channel
Analytics::Events::QrScanned.create(
  channel: "qr",          # or "nfc"
  qr_code_pid: qr.public_id,
  account_pid: qr.account.public_id,
  ...
)

# SMS — separate event (different data shape)
Analytics::Events::SmsReceived.create(
  keyword: "MAIN123",
  qr_code_pid: qr.public_id,
  account_pid: qr.account.public_id,
  phone_number_masked: "***-***-1234",  # privacy
  ...
)
```

---

## Summary

- **QR + NFC = same model, same URL, different channel attribute.**
  NFC is free — just program the tag with the scan URL.
- **SMS = new infrastructure** (Twilio, webhook, keyword) but
  same QrCode model with a `keyword` field added.
- **SMS is the highest-value channel** — passive lead capture
  without forms, works at any distance, captures phone number
  automatically.
- All three channels share the same destination resolution and
  attribution model via QrCode.
