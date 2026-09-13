# Plan: Migrate QrScan to Ahoy Event

**Created:** 2026-09-13
**Status:** Draft
**Branch:** `qrscan-to-ahoy`

## Problem

`QrScan` is a standalone model that duplicates data already captured by Ahoy. The `qr.scanned` governed event is already being fired in `ScansController` alongside `QrScan` record creation — we're dual-writing today. This plan eliminates the `QrScan` model and makes Ahoy the single source of truth for scan data.

## Decision: Visit-Level Attribution

Leads currently link to scans via `belongs_to :qr_scan`. After migration, leads use `visitable :ahoy_visit` (already in place) for attribution. The visit contains the `qr.scanned` event with all context (qr_code_id, ad_id, screen_id, destination_url, screen_content_id). Visit-level attribution is sufficient — we don't need event-level linking.

## What Changes

### Model Layer
- **Remove** `QrScan` model, migration, factory, specs
- **Remove** `Lead#qr_scan` association (`belongs_to :qr_scan`)
- **Remove** `QrCode#scans` association (`has_many :scans`)
- **Remove** `qr_scan_id` column from `leads` table
- **Keep** `QrCode` model unchanged (still manages tokens, destinations, active state)
- **Keep** `Analytics::Events::QrScanned` governed event (already exists)

### ScansController (the redirect handler)
- **Remove** `qr.scans.create!(...)` — stop creating QrScan records
- **Remove** `scan_id` from the destination URL params (no longer needed)
- **Keep** `Analytics::Events::QrScanned.create(...)` — this becomes the sole record
- The governed event already captures: `qr_code_id`, `destination_url`, `screen_content_id`, `ad_id`, `screen_id`

### Go::LeadsController
- **Remove** `@lead.qr_scan = QrScan.find_by(id: lead_params[:scan_id])` line
- **Remove** `:scan_id` from `lead_params` permit list
- Attribution now flows through `visitable :ahoy_visit` (already set up on Lead)

### Views

**QR Code Show (`app/views/app/qr_codes/show.html.erb`)**
- Replace `@scans` (QrScan records) with Ahoy events query:
  `Ahoy::Event.where(name: "qr.scanned").where("properties @> ?", { qr_code_id: @qr_code.id }.to_json)`
- Replace `@scan_count` with `.count` on the same query
- Update the scan history table to read from event properties instead of QrScan columns
- "Qualified" badge: check `properties['ad_id']` and `properties['screen_id']` presence

**QR Scans Index (`app/views/app/qr_scans/index.html.erb`)**
- Replace with Ahoy events listing for the given QR code
- Same query pattern as above, paginated

**Lead Show Attribution Panel (`app/views/app/leads/show.html.erb:56-82`)**
- Replace `@lead.qr_scan` check with: find `qr.scanned` event on the lead's Ahoy visit
- `@lead.ahoy_visit&.events&.find_by(name: "qr.scanned")`
- Read qr_code_id, ad_id, screen_id from event properties
- Look up QrCode, Ad, Screen by ID for display

**Admin Dashboard (`app/views/admin/dashboard/show.html.erb:62`)**
- Replace `QrScan.qualified.where(...)` chart query with Ahoy events query

### Controllers (queries)

**App::AdsController**
- Replace `QrScan.qualified.where(ad: @ad).count` with Ahoy event count

**App::QrScansController**
- Rewrite to query Ahoy events instead of QrScan records
- Or rename to `App::QrEventsController` / fold into QrCodesController

**Admin::QrScansController**
- Remove Administrate dashboard or convert to Ahoy events view

**Admin::DashboardController**
- Replace `QrScan.qualified.count` with Ahoy event count queries

### Helpers

**QrHelper**
- `qr_scan_full_url` — remove `scan_id` param from generated URLs
- Route helper changes: `qr_scan_url` → `qr_scan_path` (no change to public `/s/:token` route)

### Admin

- **Remove** `app/dashboards/qr_scan_dashboard.rb`
- **Remove** `resources :qr_scans` from admin routes
- **Remove** `Admin::QrScansController`

### Routes
- **Keep** `get "/s/:token"` public scan route (unchanged)
- **Keep** `resources :qr_codes` in app subdomain
- **Remove** nested `resources :scans` under qr_codes (replace with Ahoy events)
- **Remove** `resources :qr_scans` from admin

### Database
- Migration to remove `qr_scan_id` from `leads`
- Migration to drop `qr_scans` table
- Add GIN index on `ahoy_events.properties` if not already present (for jsonb queries)

### Seeds
- Remove QrScan seed block
- Add `qr.scanned` Ahoy events to seeds instead

### Specs
- Remove `spec/models/qr_scan_spec.rb`
- Remove `spec/factories/qr_scans.rb`
- Update `spec/requests/scans_spec.rb` — assert Ahoy event created, no QrScan
- Update `spec/requests/qr_scans_spec.rb` → rewrite for Ahoy events listing
- Update `spec/requests/go/leads_spec.rb` — remove scan_id linking test
- Update `spec/models/lead_spec.rb` — remove qr_scan association test
- Update `spec/requests/admin/resources_spec.rb` — remove qr_scans admin tests
- Keep `spec/analytics/events/integration_spec.rb` (already tests QrScanned)

## Performance Consideration

Dashboard queries like "count scans for this QR code" become jsonb property queries on `ahoy_events`. For the current scale this is fine. If it becomes slow:
- Add a GIN index on `ahoy_events.properties`
- Use rollups for aggregate counts (already have `AnalyticsRollupJob`)

## Execution Order

### Step 1 — GIN index on `ahoy_events.properties`
- Create migration adding GIN index for jsonb property queries
- Commit

### Step 2 — `QrCode#scan_events` convenience method (TDD)
- **RED:** Write model spec for `QrCode#scan_events` returning matching Ahoy events, `#scan_count`, and `#qualified_scan_events` (ad_id + screen_id present)
- **GREEN:** Implement methods on `QrCode`

### Step 3 — ScansController stops creating QrScan records (TDD)
- **RED:** Update `spec/requests/scans_spec.rb` — assert no `QrScan` is created, assert `qr.scanned` Ahoy event is created with correct properties, assert redirect URL no longer includes `scan_id`
- **GREEN:** Remove `qr.scans.create!(...)` from `ScansController#show`, remove `scan_id` from destination URL, remove `scan_context` helper

### Step 4 — Go::LeadsController drops scan linking (TDD)
- **RED:** Update `spec/requests/go/leads_spec.rb` — remove test for `scan_id` linking, assert lead is created without `qr_scan` association
- **GREEN:** Remove `@lead.qr_scan = ...` line, remove `:scan_id` from `lead_params`

### Step 5 — QR code show + scans index use Ahoy events (TDD)
- **RED:** Update `spec/requests/qr_codes_spec.rb` — assert show page renders scan count and recent scans from Ahoy events. Update `spec/requests/qr_scans_spec.rb` — assert index renders Ahoy events for the QR code
- **GREEN:** Update `App::QrCodesController#show` to set `@scans` and `@scan_count` from `@qr_code.scan_events`. Update `App::QrScansController#index` likewise. Update both views to read from event properties

### Step 6 — Lead show attribution from Ahoy visit (TDD)
- **RED:** Write request spec asserting lead show page renders attribution from the visit's `qr.scanned` event (qr code, ad, screen, timestamp)
- **GREEN:** Update `app/views/app/leads/show.html.erb` attribution panel to query `@lead.ahoy_visit&.events&.find_by(name: "qr.scanned")` and read properties

### Step 7 — Dashboard queries use Ahoy events (TDD)
- **RED:** Update admin dashboard spec asserting scan counts render. Update ads controller spec asserting scan count on ad show
- **GREEN:** Replace `QrScan.qualified.count` with Ahoy event queries in `Admin::DashboardController` and `App::AdsController`. Update dashboard view chart query

### Step 8 — Remove QrScan model and admin
- Remove `app/models/qr_scan.rb`, `app/dashboards/qr_scan_dashboard.rb`, `app/controllers/admin/qr_scans_controller.rb`
- Remove `has_many :scans` from `QrCode`, `belongs_to :qr_scan` from `Lead`
- Remove `spec/models/qr_scan_spec.rb`, `spec/factories/qr_scans.rb`
- Update `spec/models/lead_spec.rb`, `spec/requests/admin/resources_spec.rb` — remove QrScan references
- Remove admin and nested scan routes
- Commit

### Step 9 — Drop database columns and table
- Create migration removing `qr_scan_id` from `leads` and dropping `qr_scans` table
- Commit

### Step 10 — Seeds, cleanup, ship
- Replace QrScan seed block with `qr.scanned` Ahoy event seeds
- Update QrHelper (remove `scan_id` param logic)
- Update `CLAUDE.md` documentation
- `make lint`, `make test` — full suite green
- Push, create PR

## Out of Scope

- Migrating historical QrScan records to Ahoy events (data is already being dual-written; old data can be queried from the dropped table backup if needed)
- Adding new scan analytics features (day-parting, heatmaps — separate plan)
