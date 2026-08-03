# replay_rails

## Project Overview

replay_rails is a Rails 8.1 application with PostgreSQL, Hotwire (Turbo + Stimulus), and Tailwind CSS v4 + DaisyUI v5. It uses a multi-tenant authentication pattern with Account and User models (Rails 8 built-in authentication). Background jobs, caching, and WebSockets are handled by Solid Queue, Solid Cache, and Solid Cable (all DB-backed, no Redis).

## Development Setup

The application runs in Docker. Use these commands to get started:

```bash
make build       # Build Docker images
make up          # Start all services (web, db, css)
make migrate     # Run database migrations
make seed        # Seed the database
```

## Available Make Commands

All development commands go through the Makefile. Do not use raw `docker compose exec` commands.

| Command | Description |
|---------|-------------|
| `make test` | Run full test suite with RSpec |
| `make test-file FILE=path` | Run a single spec file |
| `make lint` | Run RuboCop linter |
| `make lint-fix` | Auto-fix RuboCop offenses |
| `make migrate` | Run database migrations |
| `make seed` | Seed the database |
| `make db-reset` | Reset the database (drop, create, migrate, seed) |
| `make generate ARGS="..."` | Run Rails generators |
| `make console` | Open Rails console |
| `make routes` | Display all routes |
| `make up` | Start Docker services |
| `make down` | Stop Docker services |
| `make build` | Build Docker images |
| `make restart` | Restart Docker services |
| `make logs` | Tail web service logs |

## Testing

The test suite uses:
- **RSpec** — Test framework (not Minitest)
- **FactoryBot** — Test data factories (`spec/factories/`)
- **Faker** — Realistic random data generation
- **shoulda-matchers** — One-liner tests for validations and associations
- **database_cleaner** — Clean database state between tests
- **Capybara** — System/integration tests with browser simulation

Run tests:
```bash
make test                          # Full suite
make test-file FILE=spec/models/user_spec.rb  # Single file
```

### TDD Workflow

Follow the red-green cycle for all implementation work:

1. **Red** — Write a failing spec first. Run it to confirm it fails.
2. **Green** — Write the minimum implementation to make the spec pass.
3. **Refactor** — Clean up without breaking the spec.

No implementation code is written without a failing spec. Factories are created in the red step, not the green step. See `agent-os/standards/testing/tdd.md` for the full standard.

## Architecture

### Authentication

Uses Rails 8 built-in authentication with a multi-tenant Account model:

- `Account` — Tenant model. All resources are scoped to an account.
- `User` — Belongs to Account. Has `email_address` and `password_digest`.
- `Session` — Tracks active sessions per user.
- `Current` — `ActiveSupport::CurrentAttributes` provides `Current.user` and `Current.session` throughout the request.

All queries must be scoped through the current account:
```ruby
Current.user.account.buildings    # Correct
Building.all                      # Wrong — leaks data across tenants
```

### Database

- PostgreSQL with `t.timestamps` placed first in all `create_table` blocks
- Migrations follow the timestamps-first convention (see `agent-os/standards/database/migrations.md`)
- Seeds use FactoryBot factories and are always idempotent (see `agent-os/standards/database/seeds.md`)

## Frontend

- **Tailwind CSS v4** with **DaisyUI v5** loaded via `@plugin "daisyui"` in `app/assets/tailwind/application.css`
- Use DaisyUI semantic classes for UI components (`btn btn-primary`, `input input-bordered`, `card`, `alert`, etc.)
- Use raw Tailwind utilities for layout and spacing (`flex`, `grid`, `mt-4`, `p-6`)
- Theme: `data-theme="light"` on the `<html>` tag
- See `agent-os/standards/frontend/daisyui-tailwind.md` for the full component class reference

## Standards

This project follows documented standards in `agent-os/standards/`. See `agent-os/standards/index.yml` for the full index.

| Standard | File | Summary |
|----------|------|---------|
| Database Migrations | `agent-os/standards/database/migrations.md` | Place `t.timestamps` first in all `create_table` blocks |
| Seed Data | `agent-os/standards/database/seeds.md` | Update seeds for every new model; use FactoryBot; always idempotent |
| TDD | `agent-os/standards/testing/tdd.md` | Write failing spec before implementing (red-green cycle) |
| Commit Cadence | `agent-os/standards/git/commit-cadence.md` | Commit after every significant step; RED and GREEN are separate commits |
| DaisyUI + Tailwind | `agent-os/standards/frontend/daisyui-tailwind.md` | Use DaisyUI v5 component classes; installed via @plugin in Tailwind CSS |
| Makefile | `agent-os/standards/tooling/makefile.md` | Use make targets instead of raw docker compose commands |
| Security & Environment | `agent-os/standards/security/environment.md` | CSP, parameter filtering, env vars, rate limiting, HTTPS |
| Code Organization | `agent-os/standards/code-organization/patterns.md` | Thin controllers, concerns, service objects, naming, tenant scoping |
| Error Handling | `agent-os/standards/error-handling/conventions.md` | Flash messages, rescue_from, form validation, logging, error pages |

## Coding Conventions

- **Thin controllers** — Controllers handle HTTP concerns only (params, redirects, status codes). Business logic lives in models or service objects.
- **Concerns for shared behavior** — Use `ActiveSupport::Concern` in `app/models/concerns/` and `app/controllers/concerns/` for reusable behavior.
- **Service objects for complex logic** — POROs in `app/services/` with a single `call` method for operations spanning multiple models.
- **Follow Rails omakase style** — RuboCop is configured with `rubocop-rails-omakase` and `rubocop-rspec`. Run `make lint` before committing.
- **Multi-tenant scoping** — Always scope queries through `Current.user.account` to prevent cross-tenant data access.
- **Flash messages** — Use `flash[:notice]` for success, `flash[:alert]` for errors. Display with DaisyUI alert components.
- **Form errors** — Re-render with `status: :unprocessable_entity` for Turbo compatibility. Display errors inline with `model.errors`.
