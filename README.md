# RePlay

Digital signage for real estate storefronts. Replace static printed property sheets in brokerage windows with managed, dynamic displays — and connect passersby to listings via QR.

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
- **Docker** for development, **Kamal** for deployment
- **RSpec** + FactoryBot for testing

## Domain Model

```
Account (tenant)
├── Sites (physical locations)
│   └── Screens (displays at a site)
│       └── ScreenPlaylist (assigned playlist)
├── Listings (properties: address, price, beds, baths, sqft, status)
│   └── ListingAgents (join: agent + role)
├── Agents (real estate agents, optionally linked to a User)
├── Ads (slides: headline, body, optional Listing link)
│   └── PlaylistAds (join: position + duration)
└── Playlists (ordered sequences of ads: draft → published → archived)
```

All resources are tenant-scoped through `Current.account`.

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

Real resources use flat controllers with optional parent filtering:

```ruby
# ScreensController — /screens or /screens?site_id=1
def index
  @screens = scope.order(:name)
end

def scope
  current_site&.screens || Current.account.screens
end
```

Join models use inherited controllers with a `parent` method:

```ruby
# Base: ListingAgentsController — shared CRUD logic
def create
  @listing_agent = parent.listing_agents.build(listing_agent_params)
  # ...redirects to parent
end

# Listings::ListingAgentsController — 3 lines
def parent = Current.account.listings.find(params[:listing_id])

# Agents::ListingAgentsController — 3 lines
def parent = Current.account.agents.find(params[:agent_id])
```

### Turbo Frames & Streams

- **Modals** — DaisyUI `<dialog>` modal in the layout, opened via Stimulus when a Turbo Frame loads content into it
- **Join model CRUD** — append/replace/remove individual rows via Turbo Streams (no collection re-fetch)
- **Lazy loading** — parent show pages load nested resource lists via `turbo_frame_tag` with `src`
- **Flash** — auto-dismissing alerts rendered via Turbo Stream on non-redirect responses

### Multi-tenancy

All queries scope through `Current.account` (delegated from `Current.user`). Join models validate same-account ownership at the model level.

## Testing

214 specs covering models, request specs, and system specs. TDD workflow: write failing spec first, then implement.

```bash
make test                              # Full suite
make test-file FILE=spec/models/site_spec.rb  # Single file
```
