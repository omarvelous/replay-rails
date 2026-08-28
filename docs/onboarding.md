# Developer Onboarding

Your first day getting RePlay running locally and making your first change.

## Prerequisites

- Docker Desktop
- Git
- A text editor

## Setup

```bash
git clone git@github.com:omarvelous/replay-rails.git
cd replay-rails
make build        # Build Docker images
make up           # Start all services (web, db, css)
make migrate      # Run database migrations
make seed         # Seed demo data
```

The app runs on `localhost:3000` with subdomain routing:

| URL | What you see |
|-----|-------------|
| `replay.localhost:3000` | Marketing site |
| `app.replay.localhost:3000` | Main application |
| `admin.replay.localhost:3000` | Admin panel (Administrate) |
| `play.replay.localhost:3000` | Player/screen playback |
| `api.replay.localhost:3000` | JSON API (device communication) |

## Demo credentials

Seeds create a demo account with users at each role level. Check `db/seeds.rb` for current credentials.

## Run the tests

```bash
make test                                    # Full suite
make test-file FILE=spec/models/user_spec.rb # Single file
```

The suite uses RSpec with FactoryBot, DatabaseCleaner, and shoulda-matchers. See [testing.md](testing.md) for details.

## Run the linter

```bash
make lint       # Check for offenses
make lint-fix   # Auto-fix
```

RuboCop is configured with `rubocop-rails-omakase`, `rubocop-rspec`, `rubocop-rspec_rails`, `rubocop-factory_bot`, and `rubocop-capybara`.

## Key files to read first

| File | Why |
|------|-----|
| `CLAUDE.md` | Project overview, conventions, standards |
| `app/models/current.rb` | How `Current.user` and `Current.account` work |
| `app/controllers/concerns/authentication.rb` | Session management |
| `app/controllers/app/base_controller.rb` | Action Policy authorization setup |
| `config/routes.rb` | Subdomain routing structure |

## Architecture at a glance

RePlay is a multi-tenant Rails 8.1 app for real estate digital signage. The core loop:

1. Brokerages create **listings** (properties) and **agents**
2. Listings become **ads** (4 types via delegated types)
3. Ads go into **playlists** (ordered sequences)
4. Playlists are assigned to **screens** (TVs in storefront windows)
5. **Players** (devices) pair to screens and display the content
6. Each ad has a **QR code** — scanning creates a **lead**

See [architecture/overview.md](architecture/overview.md) for the full picture.

## Make commands

All development commands go through the Makefile. Do not use raw `docker compose exec`.

| Command | Description |
|---------|-------------|
| `make test` | Run full test suite |
| `make test-file FILE=path` | Run a single spec file |
| `make lint` / `make lint-fix` | RuboCop linting |
| `make migrate` | Run database migrations |
| `make seed` | Seed the database |
| `make db-reset` | Drop, create, migrate, seed |
| `make generate ARGS="..."` | Run Rails generators |
| `make console` | Open Rails console |
| `make routes` | Display all routes |
| `make up` / `make down` | Start/stop Docker services |
| `make build` | Build Docker images |
| `make logs` | Tail web service logs |

## TDD workflow

Every change follows the red-green cycle:

1. **Red** — Write a failing spec. Run it. Confirm it fails.
2. **Green** — Write the minimum code to make it pass.
3. **Refactor** — Clean up without breaking the spec.

RED and GREEN are separate commits. See [testing.md](testing.md) and `.claude/standards/testing/tdd.md`.

## Next steps

- [Architecture overview](architecture/overview.md) — high-level system design
- [Domain model](architecture/domain-model.md) — every model and how they connect
- [Subdomain routing](architecture/subdomains.md) — how the 5 subdomains work
