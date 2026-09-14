# Plan: NFC Tap-to-View

**Created:** 2026-09-14
**Status:** Draft
**Branch:** `nfc-tap`

## Problem

QR codes require opening a camera app. SMS requires typing. NFC is
zero-friction: tap your phone on a tag, the Go page opens instantly.
Most modern phones (iPhone XS+, Android 5+) support NFC without an
app.

Beyond lead capture, NFC tags have an inventory angle — each tag
is a physical identifier tied to a screen location.

## How It Works

1. NFC tag is affixed to or near the screen
2. Visitor holds phone near the tag
3. Phone reads the URL from the tag → opens the Go page
4. Visitor browses listing, fills out lead form

No app needed. No camera. No typing. The tag just stores a URL.

## Design

### What the tag stores

An NFC tag contains a single NDEF URL record. The URL is the same
as the QR scan URL:

```
https://rply.tv/s/TOKEN?nfc=1
```

The `nfc=1` param lets us distinguish NFC taps from QR scans in
analytics. The existing `ScansController` handles the redirect —
the `qr.scanned` event fires with an additional `channel: "nfc"`
property (or a new `nfc.tapped` event).

### Tag Provisioning

Tags are cheap ($0.30-$0.50 each, NTAG215/NTAG216). They need to
be written once with the URL. Options:

- **Pre-programmed** — Write the URL at setup time using a phone
  app (NFC Tools, free). One-time operation per tag.
- **App-provisioned** — Future: use the RePlay mobile app or Web
  NFC API to write tags from the admin interface.

### NFC Tag Model (optional)

Could track tags in the system for inventory:

```
NfcTag
  token       : string (matches QR code token or unique)
  screen_id   : references (optional — ties tag to a screen)
  qr_code_id  : references (optional — shares QR destination)
  tag_uid     : string (hardware UID from the tag, if read)
  label       : string ("Lobby screen", "Window left")
  active      : boolean
```

**Decision needed:** Is a dedicated model worth it now, or just
use the existing QR code URL on the tag and track via the `nfc=1`
param?

Start simple: **no new model**. The NFC tag stores the same
`/s/TOKEN` URL as the QR code. Analytics distinguishes via the
`nfc=1` param. Inventory tracking can come later.

### Analytics

Option A: Reuse `qr.scanned` with a `channel` property:
```ruby
Analytics::Events::QrScanned.create(
  qr_code_id: qr.id,
  destination_url: destination,
  channel: params[:nfc] ? "nfc" : "qr",
  ...
)
```

Option B: New `nfc.tapped` governed event. Cleaner separation but
more code for similar data.

**Recommendation:** Option A — add `channel` to QrScanned. The
scan is functionally identical regardless of how the URL was opened.

### Kiosk Display

Add NFC icon + "Tap your phone here" label near the QR code on
the screen. An NFC logo is recognizable:

```
┌────────────┐  ┌──┐
│   QR CODE  │  │NFC│  Tap your phone
│            │  │ )) │  or scan to view
└────────────┘  └──┘
```

## Execution

### Step 1 — Add channel to QrScanned event
- Add `channel` attribute to `Analytics::Events::QrScanned`
- Update `ScansController` to pass `channel: "nfc"` when `nfc=1` param present, `"qr"` otherwise
- Update specs

### Step 2 — NFC icon on kiosk display
- Add NFC CTA partial alongside QR code in ad layouts and experience kiosk
- SVG icon + "Tap to view" label

### Step 3 — Tag provisioning docs
- Document how to write NFC tags with the scan URL
- Recommended tag types (NTAG215, waterproof stickers)
- Instructions for NFC Tools app

### Step 4 — Ship
- `make lint`, `make test`
- Push, create PR

## Future (Not Now)

- `NfcTag` model for inventory tracking
- Web NFC API for in-browser tag writing from admin
- Tag UID reading for device authentication
- Per-screen NFC provisioning flow in the app

## Hardware

| Item | Cost | Notes |
|------|------|-------|
| NTAG215 stickers (50-pack) | ~$15 | Waterproof, adhesive-backed |
| NTAG216 stickers (50-pack) | ~$20 | Larger memory for longer URLs |
| NFC Tools app | Free | iOS + Android, for writing tags |

## Out of Scope

- NfcTag model / admin UI (future inventory feature)
- Web NFC API integration
- Apple App Clips or Android Instant Apps
