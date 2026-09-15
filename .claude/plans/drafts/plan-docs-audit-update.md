# Plan: Documentation Audit Update

**Created:** 2026-09-15
**Status:** Draft
**Branch:** `docs-audit`

## Problem

Several developer docs reference removed models (`QrScan`, `Impression`,
`ScreenPlaylist`) and deleted API endpoints. The domain model ERD is
missing `ScreenContent`, `Experience`, and Ahoy tables. Key features
like Experiences, Public IDs, and the analytics architecture have no
documentation at all.

## Scope

### Must Fix (stale — actively misleading)

| Doc | What's wrong |
|-----|-------------|
| `docs/api/scan-api.md` | Entire doc describes `QrScan` model creation. Now fires Ahoy events with `_pid` params. Rewrite. |
| `docs/architecture/qr-codes.md` | `QrScan` model section, `.scans` association, `QrScan.qualified` scope — all removed. Rewrite scan tracking section. |
| `docs/architecture/lead-capture.md` | Attribution chain references `lead.qr_scan_id`, `QrScan` records. Now uses Ahoy visit attribution. Rewrite attribution section. |
| `docs/architecture/domain-model.md` | ERD lists `QrScan`, `Impression`, `ScreenPlaylist`. Missing `ScreenContent`, `Experience`, `Experiences::ListingExperience`, `ahoy_visits`, `ahoy_events`. Rebuild ERD and model tables. |
| `docs/architecture/player-pairing.md` | References `POST /impressions` endpoint (removed), `ScreenPlaylist` callbacks (now `ScreenContent`), no mention of experience/kiosk playback. Update playback and content sync sections. |

### Should Fix (partially stale)

| Doc | What's wrong |
|-----|-------------|
| `docs/architecture/subdomains.md` | API routes block lists `ImpressionsController` — removed. Update route listing. |
| `docs/dev/event-catalog.md` | One line: "Lead, Inquiry, and QrScan use visitable" — drop QrScan. |

### Missing (undocumented features)

| Feature | Doc to create |
|---------|--------------|
| Experiences / kiosk mode | `docs/architecture/experiences.md` — delegated types, kiosk player, idle/attract mode |
| Public IDs | `docs/architecture/public-ids.md` — `_pid`/`_sid` conventions, `PublicIdentifiable` concern, URL patterns |
| Analytics architecture | `docs/architecture/analytics.md` — Ahoy visits/events, governed event POROs, query scopes, rollups, account association |
| Experiences user doc | `app/views/docs/pages/experiences.html.erb` + entry in `config/docs.yml` |

## Execution

### Step 1 — Fix event catalog (one-line fix)
- Remove `QrScan` from the visitable line in `docs/dev/event-catalog.md`

### Step 2 — Rewrite scan API doc
- `docs/api/scan-api.md` — describe `GET /s/:token` flow, Ahoy event, `_pid` params, no `QrScan` model

### Step 3 — Rewrite QR codes architecture doc
- `docs/architecture/qr-codes.md` — `QrCode` model, `scan_events` via Ahoy, `QrScanned.qualified` scope, no `QrScan` model

### Step 4 — Rewrite lead capture doc
- `docs/architecture/lead-capture.md` — Go page flow, Ahoy visit attribution, no `qr_scan_id`

### Step 5 — Rebuild domain model doc
- `docs/architecture/domain-model.md` — update ERD, add `ScreenContent`, `Experience`, `Experiences::ListingExperience`, `ahoy_visits`, `ahoy_events`. Remove `QrScan`, `Impression`, `ScreenPlaylist`.

### Step 6 — Update player pairing doc
- `docs/architecture/player-pairing.md` — manifest polling, `ScreenContent` callbacks, experience/kiosk playback state, remove `Impression` endpoint

### Step 7 — Update subdomains doc
- `docs/architecture/subdomains.md` — remove impressions route, update API routes

### Step 8 — New: Experiences architecture doc
- `docs/architecture/experiences.md` — `ScreenContent` delegated type, `Experience` delegated type, `ListingExperience`, kiosk player, idle/attract, floor plans

### Step 9 — New: Public IDs doc
- `docs/architecture/public-ids.md` — `PublicIdentifiable` concern, `_pid`/`_sid`/`_id` conventions, `find_by_param!`, URL generation, signed IDs for forms

### Step 10 — New: Analytics architecture doc
- `docs/architecture/analytics.md` — Ahoy setup, governed event POROs, `Base.events`/`where_properties`/extending scopes, `Ahoy::Store` account enrichment, rollups, page views, exclusions

### Step 11 — New: Experiences user doc
- `app/views/docs/pages/experiences.html.erb` — what experiences are, creating one, assigning to a screen
- Add entry to `config/docs.yml`

### Step 12 — Ship
- `make lint`, `make test`
- Push, create PR

## Out of Scope

- Rewriting user docs that are already current (playlists, ads, leads, etc.)
- Go page documentation (consumer-facing, not internal docs)
- Agent branding documentation (covered by existing ad-templates.md once updated)
