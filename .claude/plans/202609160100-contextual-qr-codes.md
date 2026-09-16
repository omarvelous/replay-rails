# Plan: Contextual QR Codes

**Created:** 2026-09-15
**Status:** Draft
**Branch:** `contextual-qr-codes`

## Problem

QR scan URLs currently carry attribution as query params:

```
/s/:token?a=<ad_pid>&s=<screen_pid>&sc=<screen_content_pid>
```

This has several issues:
- Long URLs produce denser QR codes (harder to scan, more visual noise)
- Attribution is baked into the URL at render time, not the QR code record
- The governed event has to parse and store these params separately
- Params can be stripped or altered by URL sharing

## Design: Origin-based QR codes

A QR code has two polymorphic relationships:

- **`destination_record`** — where the scan goes (Listing, Agent) — already exists
- **`creative`** — the thing that renders this QR code (Ad, Experience, nil)

The scan URL becomes just the token:

```
/s/:token
```

All attribution is on the QR code record. The token alone tells you
everything: what was scanned, where it leads, and what rendered it.

## Model

### QrCode

```ruby
class QrCode < ApplicationRecord
  belongs_to :destination_record, polymorphic: true, optional: true
  belongs_to :creative, polymorphic: true, optional: true  # Ad, Experience
  belongs_to :screen_content, optional: true
end
```

New columns:
- `creative_type` — string (polymorphic type)
- `creative_id` — integer (polymorphic FK)
- `screen_content_id` — integer FK, optional

Unique constraint: `[destination_record_type, destination_record_id, creative_type, creative_id, screen_content_id]`

### Three flavors

| `destination_record` | `creative` | `screen_content` | What it is |
|---|---|---|---|
| Listing | Ad | ScreenContent | QR on a listing ad on a specific screen |
| Listing | Experience | ScreenContent | QR on a kiosk on a specific screen |
| Listing | nil | nil | Standalone — printed flyer, email, business card |
| Agent | nil | nil | Standalone agent QR code |

### What's derivable

From **creative** (Ad or Experience):
- The creative context — layout, theme, headline
- Listing (via `ad.adable.listing` or `experience.experienceable.listing`)

From **screen_content**:
- Screen (via `screen_content.screen`)
- Site (via `screen.site`)
- Content type — playlist or experience
- If playlist → the playlist itself

### Listing association change

```ruby
# Before
has_one :qr_code, as: :destination_record, dependent: :destroy

# After
has_many :qr_codes, as: :destination_record, dependent: :destroy
```

Context-aware lookup:

```ruby
def qr_code_for(creative: nil, screen_content: nil)
  qr_codes.find_or_create_by!(creative: creative, screen_content: screen_content) do |qr|
    qr.account = account
    qr.label = address.truncate(40)
  end
end
```

Usage:

```ruby
listing.qr_code_for(creative: ad, screen_content: sc)  # QR for this ad on this screen
listing.qr_code_for(creative: experience, screen_content: sc)  # QR for the kiosk on this screen
listing.qr_code_for                                    # standalone QR
```

## Scan flow

### ScansController

```ruby
def show
  qr = QrCode.find_by!(token: params[:token], active: true)
  destination = qr.resolve_destination_url(self)

  Analytics::Events::QrScanned.create(
    qr_code_pid: qr.public_id,
    destination_url: destination,
    request: request
  )
  redirect_to destination, allow_other_host: true
end
```

No params to parse. The event only carries `qr_code_pid` — all
context is on the QR code record.

### QrScanned event

```ruby
class QrScanned < Base
  self.event_name = "qr.scanned"
  attribute :qr_code_pid, :string
  attribute :destination_url, :string
  validates :qr_code_pid, :destination_url, presence: true
end
```

### Qualified scans

A scan is "contextual" when it came from a QR code with a creative
(displayed on an ad or experience, not standalone):

```ruby
# On QrCode
scope :contextual, -> { where.not(creative_type: nil) }
scope :standalone, -> { where(creative_type: nil) }

# Attribution queries
qr.scan_events.count                           # all scans for this QR
QrCode.contextual.sum(&:scan_count)            # all on-screen scans
qr.screen_content.screen                       # which screen
qr.creative                                      # which ad or experience
```

## QR rendering

### QR badge partial

```erb
<%# Before %>
<% qr = ad.listing&.qr_code %>
<%= qr_svg(qr, ad: ad, screen: @screen) %>

<%# After %>
<% qr = ad.listing&.qr_code_for(creative: ad, screen_content: @screen_content) %>
<%= qr_svg(qr) %>
```

### QR helper

```ruby
def qr_scan_full_url(qr_code)
  base = ENV.fetch("QR_BASE_URL") { ... }
  "#{base}/s/#{qr_code.token}"
end

def qr_svg(qr_code)
  url = qr_scan_full_url(qr_code)
  # ... same SVG generation, no extra params
end
```

### Experience kiosk

```erb
<%# Before %>
<%= qr_svg(@listing.qr_code) %>

<%# After %>
<%= qr_svg(@listing.qr_code_for(creative: @experience, screen_content: @screen_content)) %>
```

## Execution

### Step 1 — Migration: add creative + screen_content to qr_codes (TDD)
- **RED:** Model spec for `creative` polymorphic, `screen_content` FK, unique constraint
- **GREEN:** Migration adding `creative_type`, `creative_id`, `screen_content_id` + index

### Step 2 — `qr_code_for(creative:, screen_content:)` on Listing and Agent (TDD)
- **RED:** Spec for find-or-create with creative + screen_content, standalone fallback
- **GREEN:** Implement on a shared concern or directly on Listing/Agent

### Step 3 — Listing has_many :qr_codes
- Change `has_one` to `has_many`, remove `ensure_qr_code!`
- Update all `listing.qr_code` references to use `qr_code_for`

### Step 4 — Simplify ScansController + QrScanned event
- Remove URL param parsing from controller
- Remove `ad_pid`, `screen_pid`, `screen_content_pid` from QrScanned
- Update specs

### Step 5 — Update QR badge partial + helper
- `_qr_badge` uses `qr_code_for(creative: ad, screen_content: @screen_content)`
- `qr_scan_full_url` drops all query params
- `qr_svg` takes only a QR code

### Step 6 — Update experience kiosk QR
- Experience template uses `qr_code_for(creative: @experience, screen_content: @screen_content)`

### Step 7 — Update manifest
- Include contextual QR code token per ad
- Player renders the right QR code per slide

### Step 8 — Update qualified scans / dashboards
- Replace property-based `qualified` scope with creative-based `contextual` scope
- Update dashboard and controller queries

### Step 9 — Seeds, docs, ship
- Update seeds for contextual QR codes
- Update QR codes architecture doc
- `make lint`, `make test`
- Push, create PR

## Migration strategy

Existing QR codes remain as standalone (`creative: nil`). Contextual
QR codes are created on-demand via `qr_code_for(creative:)` when
the player renders an ad or experience. No data migration needed.

## Out of Scope

- QR code management UI for contextual codes (auto-created)
- Cleanup of orphaned contextual codes when ads are deleted
  (they stay for historical scan data)
- NFC tags (separate plan, but will use the same creative pattern)
