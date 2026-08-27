# Plan: QR Scan Attribution (hybrid model)

## Context

QR scans need attribution — which ad and which screen drove the scan.
These are the two non-derivable dimensions. Everything else (player,
site, playlist, listing) joins through them.

Currently `QrScan` has a polymorphic `source` — a single record. That
only captures one dimension. We need both ad and screen, plus room for
future context we haven't anticipated.

---

## Updated `QrScan` model

```ruby
class QrScan < ApplicationRecord
  belongs_to :qr_code
  belongs_to :account

  # Structured — the two dimensions we query on
  belongs_to :ad, optional: true
  belongs_to :screen, optional: true

  # Unstructured — everything else, processed async
  # e.g. { playlist_id: 5, slide_position: 3 }
  store_accessor :context, :playlist_id, :slide_position

  # A "qualified" scan has both ad and screen — it came from a player.
  # Scans without both are still recorded (admin previews, direct URL
  # visits) but excluded from analytics counts.
  scope :qualified, -> { where.not(ad_id: nil).where.not(screen_id: nil) }
  scope :unqualified, -> { where(ad_id: nil).or(where(screen_id: nil)) }
end
```

Drop the polymorphic `source_type` / `source_id` columns. Replace with
explicit `ad_id` and `screen_id` FKs plus a `context` JSONB column.

`ad_id` and `screen_id` are nullable — every scan is recorded regardless
of context. The `qualified` scope filters to only scans with full
attribution (from a player). Admin previews and direct URL visits are
recorded but excluded from counts.

---

## Migration

```ruby
class UpdateQrScans < ActiveRecord::Migration[8.1]
  def change
    remove_index  :qr_scans, [ :source_type, :source_id ]
    remove_column :qr_scans, :source_type, :string
    remove_column :qr_scans, :source_id, :bigint

    add_reference :qr_scans, :ad, foreign_key: true
    add_reference :qr_scans, :screen, foreign_key: true
    add_column    :qr_scans, :context, :jsonb, default: {}
  end
end
```

---

## Scan URL format

Short params, no type prefixes needed since each param is its own key:

```
/s/Ab3kX9?a=456&s=123
```

| Param | Meaning |
|-------|---------|
| `a` | Ad ID |
| `s` | Screen ID |

Minimal URL length for QR density. Future params can be added without
changing existing QR codes (old codes just won't have the new params).

---

## Updated ScansController

```ruby
# app/controllers/scans_controller.rb
class ScansController < ApplicationController
  skip_before_action :require_authentication

  def show
    qr = QrCode.find_by!(token: params[:token], active: true)

    qr.scans.create!(
      account: qr.account,
      ad_id: params[:a],
      screen_id: params[:s],
      context: scan_context,
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

    def scan_context
      ctx = {}
      ctx[:playlist_id] = params[:p].to_i if params[:p].present?
      ctx
    end
end
```

---

## Updated QR helper

```ruby
# app/helpers/qr_helper.rb
module QrHelper
  def qr_svg(qr_code, ad: nil, screen: nil)
    url = qr_scan_url(token: qr_code.token)
    query = {}
    query[:a] = ad.id if ad
    query[:s] = screen.id if screen
    url += "?#{query.to_query}" if query.any?

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

### Rendering in layout partials

```erb
<%# Admin preview — ad context only, no screen %>
<%= qr_svg(qr, ad: ad) %>

<%# Player view — both ad and screen context %>
<%= qr_svg(qr, ad: pa.ad, screen: @screen) %>
```

---

## Updated QR badge partial

```erb
<%# app/views/ads/layouts/_qr_badge.html.erb %>
<% qr = ad.listing&.qr_code %>
<div class="absolute rounded-xl overflow-hidden bg-white"
     style="right: var(--s-pad-lg); bottom: var(--s-pad-lg); width: var(--s-qr); height: var(--s-qr); padding: var(--s-xs);">
  <% if qr %>
    <%= qr_svg(qr, ad: ad, screen: defined?(@screen) ? @screen : nil) %>
  <% else %>
    <span class="grid place-items-center w-full h-full"
          style="font-size: var(--s-sm); color: #999;">QR</span>
  <% end %>
</div>
```

`@screen` is only set in the player controller. In admin preview it's
nil, so the QR URL only includes `?a=456`. On the player it includes
both `?a=456&s=123`.

---

## Analytics queries

All counts use `.qualified` — only scans with both ad and screen.
Unqualified scans (admin previews, direct visits) are recorded but
excluded from metrics.

```ruby
# Scans from a specific ad (across all screens)
QrScan.qualified.where(ad: @ad).count

# Scans from a specific screen (across all ads)
QrScan.qualified.where(screen: @screen).count

# Scans for a listing (across all QR codes pointing at it)
QrScan.qualified.joins(:qr_code).where(
  qr_codes: { destination_record_type: "Listing", destination_record_id: @listing.id }
).count

# Scans from a specific ad on a specific screen
QrScan.qualified.where(ad: @ad, screen: @screen).count

# Total scans including unqualified (for debugging/audit)
QrScan.where(qr_code: qr_code).count

# Unqualified scans (admin previews, direct visits)
QrScan.unqualified.where(qr_code: qr_code).count
```

---

## Async processing (future)

The `context` JSONB column is a raw event bag. A background job can
process new scans and denormalize into a `scan_metrics` table:

```ruby
# app/jobs/process_scan_job.rb (future)
class ProcessScanJob < ApplicationJob
  def perform(qr_scan_id)
    scan = QrScan.find(qr_scan_id)
    # Denormalize: resolve site, player, playlist from ad + screen
    # Write to scan_metrics table for dashboard queries
  end
end
```

Enqueued after each scan:
```ruby
qr.scans.create!(...)
ProcessScanJob.perform_later(scan.id)
```

Deferred until we build the analytics dashboard.

---

## Build order

1. Migration: drop source polymorphic, add ad_id, screen_id, context JSONB
2. Update QrScan model: explicit belongs_to ad/screen, store_accessor
3. Update ScansController: read `a` and `s` params
4. Update QrHelper: accept `ad:` and `screen:` keyword args
5. Update QR badge partial: pass ad and screen context
6. Update player play view: pass `@screen` to QR rendering
7. Update show page scan counts: `QrScan.qualified.where(ad: @ad).count`
8. Update specs

---

## What's deferred

- **ProcessScanJob** — async denormalization into scan_metrics
- **Analytics dashboard** — time-series, ad vs screen breakdowns
- **Playlist attribution** — add `p` param for playlist_id in scan URL
- **Geolocation from IP** — enrich scans with approximate location
