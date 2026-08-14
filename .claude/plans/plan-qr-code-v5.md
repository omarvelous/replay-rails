# Plan: QR Code Integration (v5 — QR belongs to destination)

_Supersedes `plan-qr-code-v4.md`._

## What changed from v4

- **Removed `qr_code_id` FK on ads** — the ad doesn't reference a QR code.
  The layout partial reaches through the adable to the destination record
  (e.g. `ad.adable.listing.qr_code`).
- **QR code belongs to the destination record** — a Listing has one QR code,
  an Agent has one QR code. The QR code is the public entry point for that
  record, not for the ad that displays it.
- **No auto-creation callback on ListingAd** — QR codes are created on the
  destination record (Listing, Agent) when needed. Multiple ads showing the
  same listing share the same QR code.

---

## Core concept

```
Ad (what's displayed on the screen)
  → ListingAd → Listing → QrCode → QrScan (with source: Ad.456)
  → AgentAd  → Agent   → QrCode → QrScan (with source: Ad.789)
  → BrandAd  → (no destination record, uses destination_url on QrCode)
```

The QR code is the public door to a record. An ad just renders it.
The scan records which surface drove the scan (the ad, a flyer, etc.)
via URL params at scan time.

---

## The `QrCode` model

```ruby
class QrCode < ApplicationRecord
  belongs_to :account
  belongs_to :destination_record, polymorphic: true, optional: true

  has_many :scans, class_name: "QrScan", dependent: :destroy

  validates :token, presence: true, uniqueness: true

  before_create :generate_token

  def destination?
    destination_url.present? || destination_record.present?
  end

  private

    def generate_token
      self.token = SecureRandom.urlsafe_base64(8)
    end
end
```

### Fields

| Column | Type | Purpose |
|--------|------|---------|
| `token` | string, unique | Short identifier encoded in the QR URL |
| `account_id` | FK | Tenant scoping |
| `destination_record_type` + `destination_record_id` | polymorphic, optional | Internal page (Listing, Agent, etc.) |
| `destination_url` | string, optional | External URL redirect |
| `label` | string, optional | Human name |
| `active` | boolean, default true | Toggle off without deleting |

### Migration

```ruby
create_table :qr_codes do |t|
  t.timestamps
  t.references :account, null: false, foreign_key: true
  t.string  :token, null: false
  t.string  :destination_record_type
  t.bigint  :destination_record_id
  t.string  :destination_url
  t.string  :label
  t.boolean :active, null: false, default: true
end
add_index :qr_codes, :token, unique: true
add_index :qr_codes, [ :destination_record_type, :destination_record_id ]
```

---

## Associations on destination records

```ruby
# app/models/listing.rb
has_one :qr_code, as: :destination_record, dependent: :destroy

# app/models/agent.rb
has_one :qr_code, as: :destination_record, dependent: :destroy
```

A listing gets a QR code created when the user first wants one (or
auto-created when first rendered on an ad). Every ad that features that
listing renders the same QR code.

---

## The `QrScan` model

The scan event. Records what was scanned and where it was displayed.

```ruby
class QrScan < ApplicationRecord
  belongs_to :qr_code
  belongs_to :account
  belongs_to :source, polymorphic: true, optional: true
end
```

### Migration

```ruby
create_table :qr_scans do |t|
  t.timestamps
  t.references :qr_code, null: false, foreign_key: true
  t.references :account, null: false, foreign_key: true
  t.string :source_type
  t.bigint :source_id
  t.string :ip_address
  t.string :user_agent
end
add_index :qr_scans, [ :qr_code_id, :created_at ]
add_index :qr_scans, [ :source_type, :source_id ]
```

---

## Routes

```ruby
# Public scan endpoint — no auth
get "/s/:token", to: "scans#show", as: :qr_scan

# Public destination pages — no auth
namespace :go do
  resources :listings, only: :show
  resources :agents, only: :show
end
```

---

## Scan controller

```ruby
# app/controllers/scans_controller.rb
class ScansController < ApplicationController
  skip_before_action :require_authentication

  def show
    qr = QrCode.find_by!(token: params[:token], active: true)

    qr.scans.create!(
      account: qr.account,
      source_type: source_type,
      source_id: source_id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    if qr.destination_url.present?
      redirect_to qr.destination_url, allow_other_host: true
    elsif qr.destination_record.present?
      redirect_to polymorphic_path([ :go, qr.destination_record ])
    else
      redirect_to root_path
    end
  end

  private

    def source_type
      params[:src]&.split(".")&.first
    end

    def source_id
      params[:src]&.split(".")&.last&.to_i
    end
end
```

---

## Public listing page

```ruby
# app/controllers/go/listings_controller.rb
module Go
  class ListingsController < ApplicationController
    skip_before_action :require_authentication
    layout "public"

    def show
      @listing = Listing.find(params[:id])
      @agents = @listing.agents
    end
  end
end
```

**Content:** Hero photo, price, address, beds/baths/sqft, agent contact
info with `tel:` and `mailto:` links, status badge, "Powered by RePlay" footer.

---

## QR generation

```ruby
# Gemfile
gem "rqrcode", "~> 2.2"
```

```ruby
# app/helpers/qr_helper.rb
module QrHelper
  def qr_svg(qr_code, source: nil)
    url = qr_scan_url(token: qr_code.token)
    url += "?src=#{source}" if source.present?
    qr = RQRCode::QRCode.new(url)
    qr.as_svg(
      offset: 0,
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true
    ).html_safe
  end
end
```

---

## QR code lifecycle

### When is a QR code created?

When a listing (or agent) needs a public QR code for the first time.
Use `find_or_create`:

```ruby
# app/models/listing.rb
def ensure_qr_code!
  qr_code || create_qr_code!(account: account, label: address.truncate(40))
end
```

### When is it rendered?

The layout partial reaches through the adable to the destination record:

```erb
<%# In ads/layouts/_hero.html.erb %>
<%
  # Reach through to the destination record's QR code
  destination = ad.listing  # convenience method on Ad → adable.try(:listing)
  qr = destination&.qr_code
%>
<div class="absolute rounded-xl overflow-hidden bg-white"
     style="right: var(--s-pad-lg); bottom: var(--s-pad-lg); width: var(--s-qr); height: var(--s-qr); padding: var(--s-xs);">
  <% if qr %>
    <%= qr_svg(qr, source: "Ad.#{ad.id}") %>
  <% else %>
    <span class="grid place-items-center w-full h-full"
          style="font-size: var(--s-sm); color: var(--ad-text-faint);">QR</span>
  <% end %>
</div>
```

For `AgentAd`:
```erb
<% qr = ad.adable.agent.qr_code %>
<%= qr_svg(qr, source: "Ad.#{ad.id}") if qr %>
```

For `BrandAd` with a custom URL:
```erb
<%# BrandAd could have a standalone QrCode with destination_url %>
```

### Multiple ads, same listing, same QR

If three ads all feature 350 Fifth Ave, they all render the same QR code
(the listing's QR code). Each scan records a different source (`Ad.1`,
`Ad.2`, `Ad.3`), so you know which ad drove the scan.

---

## Scan analytics

```ruby
# Scans from a specific Ad (across all QR codes it displayed)
QrScan.where(source_type: "Ad", source_id: @ad.id).count

# Scans for a Listing (its QR code, all sources)
@listing.qr_code&.scans&.count || 0

# Scans for a Listing from a specific Ad
@listing.qr_code&.scans&.where(source_type: "Ad", source_id: @ad.id)&.count || 0

# Scans for an Agent's listings
QrScan.joins(:qr_code).where(
  qr_codes: { destination_record_type: "Listing", destination_record_id: @agent.listing_ids }
).count

# Organic scans (no source — printed flyer, business card, etc.)
@listing.qr_code&.scans&.where(source_type: nil)&.count || 0
```

---

## Build order

### Phase A — Schema
1. Add `rqrcode` gem
2. QrCode model — spec, factory, migration, model (RED/GREEN)
3. QrScan model — spec, factory, migration, model (RED/GREEN)
4. Add `has_one :qr_code` to Listing and Agent

### Phase B — Scan flow
5. Scan route + controller with source param parsing (RED/GREEN)
6. Public listing page — `/go/listings/:id` controller, layout, view (RED/GREEN)

### Phase C — Generation + rendering
7. `QrHelper#qr_svg` with source param
8. `Listing#ensure_qr_code!` for lazy creation
9. Replace placeholder QR in layout partials — reach through adable
10. QR section on Listing show page (scan count, download link)

### Phase D — Analytics
11. Scan counts on Ad show (by source), Listing show (total), Agent show (across listings)

### Phase E — Polish
12. Download QR as SVG
13. Active/inactive toggle
14. Backfill: create QR codes for existing listings
15. Seeds with QR codes

---

## What's deferred

- **Agent public page** — `/go/agents/:id`
- **Contact form landing page** — needs Lead/Inquiry model
- **Per-screen attribution** — player renders with `src=Screen.789`
- **Scan analytics dashboard** — time-series, source breakdowns
- **Rate limiting** — Rack::Attack on `/s/:token`
- **Open Graph tags** — OG meta on public pages
- **QR customization** — brand colors, logo overlay
- **Print export** — PDF with QR + listing details
- **Public tokens / UUIDs** — replace IDs in public URLs
