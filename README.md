# RePlay

Digital signage purpose-built for real estate storefronts. Replace static printed property sheets in brokerage windows with managed, dynamic displays — and connect passersby to listings via QR codes.

## Getting Started

The application runs in Docker. You need Docker and Docker Compose installed.

```bash
make build       # Build Docker images
make up          # Start all services (web, db, css)
make migrate     # Run database migrations
make seed        # Seed the database
```

Then visit [http://localhost:3000](http://localhost:3000).

**Demo login:** `demo@example.com` / `password`

## Tech Stack

- **Rails 8.1** with PostgreSQL
- **Hotwire** (Turbo + Stimulus) for SPA-like interactions
- **Tailwind CSS v4** + **DaisyUI v5** for UI
- **Solid Queue / Cache / Cable** — DB-backed, no Redis
- **ActionCable** for real-time player updates (Solid Cable adapter)
- **ActiveStorage** for image uploads (libvips for variants)
- **Docker** for development, **Kamal** for deployment
- **RSpec** + FactoryBot + SimpleCov for testing (399 specs, 97% line coverage)

## Domain Model

```
Account (tenant)
├── Sites (physical locations)
│   └── Screens (displays at a site)
│       ├── ScreenPlaylist (assigned playlist)
│       └── ScreenPlayer (player pairing — active + history)
├── Listings (properties: address, price, beds, baths, sqft, status)
│   ├── ListingAgents (join: agent + role)
│   ├── Photos (ActiveStorage attachments)
│   └── QrCode (public entry point, scannable)
├── Agents (real estate agents, optionally linked to a User)
├── Ads (delegated types — content for screens)
│   ├── ListingAd (single listing, badge: just_listed/open_house/sold/price_reduction/coming_soon)
│   ├── CollectionAd (multiple ads in a grid via CollectionAdAd)
│   ├── AgentAd (agent spotlight)
│   └── BrandAd (freeform headline + body)
├── Playlists (ordered sequences of ads: draft → published → archived)
│   └── PlaylistAds (join: position + duration)
├── Players (physical devices — token, pairing code, heartbeat)
└── QrCodes (scannable links — token, destination, scan tracking)
    └── QrScans (scan events — ad, screen, IP, context JSONB)
```

All resources are tenant-scoped through `Current.account`.

## Ad Templates

Ads use **delegated types** — each type is its own model with its own table, validations, controller, and form. The base `Ad` model holds common fields (headline, body, layout, theme).

| Type | Purpose | Layouts |
|------|---------|---------|
| ListingAd | Single property with badge | hero, split, minimal, stat_grid |
| CollectionAd | Multiple ads in a grid | grid |
| AgentAd | Agent spotlight | profile, split |
| BrandAd | Freeform branding | hero, minimal |

### Themes

CSS custom properties on `.ad-canvas` with dark as the CSS default. Light and brand themes override via inline styles from a hash lookup in `AdsHelper`. No case statements.

### Signage Scale

All text, padding, gaps, and QR code sizes use `cqw` (container query width) units — the ad scales proportionally whether rendered full-screen on a 55" TV, in the admin preview, or as an index card thumbnail.

## Player Pairing

Physical devices pair to screens via a 6-character code:

1. Device boots → `POST /player/register` → shows pairing code on screen
2. Admin enters code on the Screen show page → `screen.pair_player!(player)`
3. Device detects pairing (ActionCable + polling fallback) → transitions to playback
4. Device heartbeats every 30s → screen shows online/offline status

`ScreenPlayer` join model preserves pairing history (who paired, when, unpaired_at).

## QR Codes

QR codes belong to destination records (Listing, Agent). Scans record ad + screen attribution via URL params (`/s/:token?a=456&s=123`). Only scans with both dimensions are "qualified" and counted in metrics.

Public landing pages live under `/go/` (e.g. `/go/listings/42`) — mobile-first, no auth required.

## Development Commands

| Command | Description |
|---------|-------------|
| `make test` | Run full test suite (RSpec) |
| `make test-file FILE=path` | Run a single spec file |
| `make lint` | Run RuboCop linter |
| `make lint-fix` | Auto-fix RuboCop offenses |
| `make migrate` | Run database migrations |
| `make seed` | Seed the database |
| `make db-reset` | Reset the database |
| `make generate ARGS="..."` | Run Rails generators |
| `make console` | Open Rails console |
| `make routes` | Display all routes |
| `make up` | Start Docker services |
| `make down` | Stop Docker services |
| `make build` | Build Docker images |
| `make restart` | Restart Docker services |
| `make logs` | Tail web service logs |

## Architecture

### Controllers

Namespaced ad type controllers under `Ads::`:

```
AdsController              — index, show, destroy, preview (all types)
Ads::ListingAdsController  — new, create, edit, update
Ads::CollectionAdsController
Ads::AgentAdsController
Ads::BrandAdsController
```

Player API (token auth, no session):

```
PlayerApiController — register, status, play, heartbeat
```

Public pages (no auth):

```
ScansController     — GET /s/:token (record scan, redirect)
Go::ListingsController — GET /go/listings/:id
```

### Multi-tenancy

All queries scope through `Current.account`. Join models validate same-account ownership at the model level.

### ActionCable

- **PairingChannel** — anonymous, streams by pairing code for instant pair detection
- **ScreenChannel** — token-authenticated, streams by screen for live playlist updates
- **ScreenPlaylist** — broadcasts `playlist_changed` on create/update/destroy

## Testing

399 specs covering models, request specs, channel specs, and system specs. SimpleCov enforces minimum coverage (95% line, 80% branch). TDD workflow: write failing spec first, then implement.

```bash
make test                                    # Full suite
make test-file FILE=spec/models/ad_spec.rb   # Single file
```

## Static Previews

Browse all ad template permutations at `/previews/index.html` — listing ads (5 badges × 4 layouts × 3 themes), collection ads, agent ads, brand ads. Styled for signage readability with contrast and font-weight fixes from the digital signage CSS analysis.
