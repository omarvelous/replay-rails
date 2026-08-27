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

The app uses subdomain routing. Visit:

| URL | Purpose |
|-----|---------|
| [replay.localhost:3000](http://replay.localhost:3000) | Marketing site |
| [app.replay.localhost:3000](http://app.replay.localhost:3000) | App (login here) |
| [admin.replay.localhost:3000](http://admin.replay.localhost:3000) | Admin panel (Administrate) |
| [play.replay.localhost:3000](http://play.replay.localhost:3000) | Player screens (HTML) |
| [api.replay.localhost:3000](http://api.replay.localhost:3000) | Player API (JSON) |

**Demo logins** (at `app.replay.localhost:3000`):

| Email | Password | Role |
|-------|----------|------|
| `demo@example.com` | `password` | Owner |
| `manager@example.com` | `password` | Manager |
| `jane.broker@example.com` | `password` | Agent |

## Tech Stack

- **Rails 8.1** with PostgreSQL
- **Hotwire** (Turbo + Stimulus) for SPA-like interactions
- **Tailwind CSS v4** + **DaisyUI v5** for UI
- **Solid Queue / Cache / Cable** — DB-backed, no Redis
- **ActionCable** for real-time player updates (Solid Cable adapter)
- **ActiveStorage** for image uploads (libvips for variants)
- **Pundit** for role-based authorization (policy classes per model)
- **Rack::Attack** for rate limiting and abuse prevention
- **Administrate** for internal admin panel
- **Docker** for development, **Kamal** for deployment
- **RSpec** + FactoryBot + SimpleCov for testing (546 specs, 95% line coverage)

## Domain Model

```
Account (tenant)
├── AccountUsers (join: user + role — owner/manager/agent)
├── Sites (physical locations)
│   └── Screens (displays at a site)
│       ├── ScreenPlaylist (assigned playlist)
│       └── ScreenPlayer (player pairing — active + history)
├── Listings (properties: address, price, beds, baths, sqft, status)
│   ├── ListingAgents (join: agent + role + primary_at)
│   ├── Leads (contact form submissions)
│   ├── Photos (ActiveStorage attachments)
│   └── QrCode (public entry point, scannable)
├── Agents (real estate agents, optionally linked to a User)
├── Ads (delegated types under Ads:: namespace)
│   ├── Ads::ListingAd (single listing, badge modifier)
│   ├── Ads::CollectionAd (multiple ads in a grid via CollectionAdAd)
│   ├── Ads::AgentAd (agent spotlight)
│   └── Ads::BrandAd (freeform headline + body)
├── Playlists (ordered sequences of ads: draft → published → archived)
│   └── PlaylistAds (join: position + duration)
├── Players (physical devices — token, pairing code, heartbeat)
├── QrCodes (scannable links — token, destination, scan tracking)
│   └── QrScans (scan events — ad, screen, IP, context JSONB)
└── Leads (contact form submissions — name, email, phone, message)
    └── LeadAgents (agent assignment history)
```

Users belong to accounts through `AccountUser` (many-to-many). The role
lives on the join — a user can be an owner at one brokerage and an agent
at another. All resources are tenant-scoped through `Current.account`.

## RBAC

Three roles per account membership, enforced by Pundit policy classes:

| Role | Access |
|------|--------|
| **Owner** | Everything. Billing, team management, delete account. |
| **Manager** | CRUD all resources. Invite agents. Manage all leads. |
| **Agent** | View/edit own listings and leads. Read-only on shared resources. |

Agent scoping uses existing join tables — agents see listings through
`ListingAgent` and leads through `LeadAgent`. Pundit `policy_scope`
handles this transparently in controllers.

The `admin` boolean on User is separate — it gates the internal
Administrate panel for RePlay staff, not customer-facing roles.

## Ad Templates

Ads use **delegated types** — each type is its own model (namespaced under `Ads::`) with its own table, validations, controller, and form. The base `Ad` model holds common fields (headline, body, layout, theme).

| Type | Purpose | Layouts |
|------|---------|---------|
| Ads::ListingAd | Single property with badge | hero, split, minimal, stat_grid |
| Ads::CollectionAd | Multiple ads in a grid | grid |
| Ads::AgentAd | Agent spotlight | profile, split |
| Ads::BrandAd | Freeform branding | hero, minimal |

### Themes

CSS custom properties on `.ad-canvas` with dark as the CSS default. Light and brand themes override via inline styles from a hash lookup in `AdsHelper`. No case statements.

### Signage Scale

All text, padding, gaps, and QR code sizes use `cqw` (container query width) units — the ad scales proportionally whether rendered full-screen on a 55" TV, in the admin preview, or as an index card thumbnail.

## Lead Capture

QR scans lead to public landing pages where visitors submit contact forms. Leads flow through a pipeline:

```
QR scan → landing page → contact form → Lead created → agent notified → inbox
```

### How it works

1. **Three lead surfaces** — listing page (`/go/listings/:id`), agent page (`/go/agents/:id`), and marketing site. All post to a single `/go/leads` endpoint.
2. **Attribution** — scan ID passes through as a query param. The lead links to the QR scan, which chains to the ad, screen, site, and listing.
3. **Agent assignment** — `LeadAgent` join table tracks assignment history. Current agent = most recent row. Reassignment via dedicated `/leads/:id/lead_agents/new` page.
4. **Status workflow** — new → contacted → qualified → closed. Filter and manage in the app inbox with sidebar unread badge.
5. **Email notification** — `LeadMailer#new_lead` sends to the assigned agent (or account owner as fallback) via `deliver_later`.
6. **Spam prevention** — honeypot field on the form silently discards bot submissions.

### Dev tools for email

- **Letter Opener Web** — browse intercepted emails at [localhost:3000/letter_opener](http://localhost:3000/letter_opener)
- **Mailer Previews** — design templates at [localhost:3000/rails/mailers](http://localhost:3000/rails/mailers)

## Rate Limiting

Rack::Attack throttles all public endpoints:

| Endpoint | Limit | Period |
|----------|-------|--------|
| Lead form | 10 | 1 hour |
| QR scans | 60 | 1 min |
| Player register | 5 | 1 hour |
| Account signup | 5 | 1 hour |
| Login | 10/IP, 5/email | 15 min |
| Password reset | 3/email | 1 hour |

Returns 429 with `Retry-After` header when exceeded. Disabled in test
environment by default.

## Player Pairing

Physical devices pair to screens via a 6-character code:

1. Device opens `play.replay.com/players/new` → JS registers via `api.replay.com/players` → shows pairing code on screen
2. Admin enters code on the Screen show page → `screen.pair_player!(player)`
3. Device detects pairing (ActionCable + polling fallback) → transitions to playback
4. Device heartbeats every 30s → screen shows online/offline status

`ScreenPlayer` join model preserves pairing history (who paired, when, unpaired_at).

## QR Codes

QR codes belong to destination records (Listing, Agent). Scans record ad + screen attribution via URL params (`/s/:token?a=456&s=123`). Scan ID passes through to landing pages for lead attribution. Only scans with both ad and screen are "qualified."

Public landing pages live under `/go/` (e.g. `/go/listings/42`, `/go/agents/7`) — mobile-first, no auth required.

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

### Subdomain Routing

| Subdomain | Module | Purpose |
|-----------|--------|---------|
| `replay.com` | `Marketing::` | Public marketing pages |
| (none) | `Go::` | Public landing pages (`/go/listings`, `/go/agents`, `/go/leads`) |
| `app.replay.com` | `App::` | Authenticated product (all CRUD) |
| `admin.replay.com` | `Admin::` | Internal admin panel (Administrate) |
| `play.replay.com` | `Play::` | Player screens — pairing and playback (HTML) |
| `api.replay.com` | `Api::` | Player API — register, status, heartbeat, impressions (JSON) |
| any | `ScansController` | `/s/:token` scan redirect |

### Controllers

App controllers namespaced under `App::`:

```
App::SitesController           — sites CRUD
App::ScreensController         — screens CRUD
App::ListingsController        — listings CRUD (agent-scoped for agent role)
App::AgentsController          — agents CRUD (agents can edit own profile)
App::AdsController             — ads index, show, destroy, preview
App::Ads::ListingAdsController — listing ad new, create, edit, update
App::Ads::CollectionAdsController
App::Ads::AgentAdsController
App::Ads::BrandAdsController
App::PlaylistsController       — playlists CRUD
App::LeadsController           — lead inbox (index, show, update)
App::LeadAgentsController      — agent assignment (new, create)
App::AccountsController        — signup (new, create)
```

Public (no auth, marketing subdomain):

```
Marketing::PagesController — home, features, pricing, about
Go::ListingsController     — public listing landing page
Go::AgentsController       — public agent landing page
Go::LeadsController        — lead form submission
```

Admin (Administrate, `admin` subdomain):

```
Admin::ApplicationController — base with auth + require_admin!
Admin::DashboardController   — platform stats
Admin::{Resource}Controller  — CRUD for all models
```

Player screens (`play` subdomain, HTML):

```
Play::PlayersController — new (pairing screen), show (playback)
```

Player API (`api` subdomain, JSON, token-in-URL auth):

```
Api::PlayersController              — create (register), show (status)
Api::Players::HeartbeatsController  — create (device health)
Api::Players::ImpressionsController — create (ad impression, future)
```

### Multi-tenancy & Authorization

Users belong to accounts through `AccountUser` (many-to-many with role).
`Current.account_user` is set on login and provides both the account
context and the role. `Current.account` delegates through it.

Every app controller action calls `authorize @record` (Pundit) and
index actions use `policy_scope` to filter records by role. Policy
classes live in `app/policies/`.

### ActionCable

- **PairingChannel** — anonymous, streams by pairing code for instant pair detection
- **ScreenChannel** — token-authenticated, streams by screen for live playlist updates
- **ScreenPlaylist** — broadcasts `playlist_changed` on create/update/destroy

## Testing

546 specs covering models, policies, request specs, mailer specs, and channel specs. SimpleCov enforces minimum coverage (95% line, 80% branch). TDD workflow: write failing spec first, then implement.

```bash
make test                                    # Full suite
make test-file FILE=spec/models/ad_spec.rb   # Single file
```

### Linting

RuboCop with `rubocop-rails-omakase`, `rubocop-rspec`, `rubocop-rspec_rails`, `rubocop-factory_bot`, and `rubocop-capybara`.

```bash
make lint        # Check
make lint-fix    # Auto-fix
```

## Static Previews

Browse all ad template permutations at `/previews/index.html` — listing ads (5 badges x 4 layouts x 3 themes), collection ads, agent ads, brand ads. Styled for signage readability with contrast and font-weight fixes from the digital signage CSS analysis.
