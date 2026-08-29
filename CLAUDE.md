# replay_rails

## Project Overview

replay_rails is a Rails 8.1 application with PostgreSQL, Hotwire (Turbo + Stimulus), and Tailwind CSS v4 + DaisyUI v5. It uses a multi-tenant authentication pattern with Account, User, and AccountUser models (Rails 8 built-in authentication). Authorization is handled by Action Policy with policy classes per model. Background jobs, caching, and WebSockets are handled by Solid Queue, Solid Cache, and Solid Cable (all DB-backed, no Redis).

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
- **pundit-matchers** — Policy spec matchers (`permit_action`, `forbid_action`)
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

No implementation code is written without a failing spec. Factories are created in the red step, not the green step. See `.claude/standards/testing/tdd.md` for the full standard.

## Architecture

### Authentication & Multi-tenancy

Uses Rails 8 built-in authentication with a many-to-many Account-User relationship:

- `Account` — Tenant model. All resources are scoped to an account.
- `User` — Has `email_address` and `password_digest`. Can belong to multiple accounts.
- `AccountUser` — Join model between User and Account. Carries the `role` (owner, manager, agent).
- `Session` — Tracks active sessions per user.
- `Current` — `ActiveSupport::CurrentAttributes` provides `Current.user`, `Current.account_user`, and `Current.account` throughout the request.

`Current.account_user` is set on login/session resume and provides both the account context and the user's role within that account. `Current.account` delegates through it.

Tenant isolation is enforced at the model level via `acts_as_tenant :account`. When a tenant is set (authenticated controllers), all queries on scoped models are automatically filtered by account. No need to prefix with `Current.account.`:

```ruby
Listing.all                       # Automatically scoped to current tenant
Listing.find(id)                  # Only finds within current tenant
```

In contexts without a tenant (admin, public pages, background jobs), use `ActsAsTenant.without_tenant` or `ActsAsTenant.with_tenant(account)` blocks.

### Authorization (Action Policy)

Every app controller action calls `authorize! @record` and index actions use `authorized_scope`. Policy classes live in `app/policies/`.

- `ApplicationPolicy` — default: read-all, write-managers+
- `ListingPolicy` / `LeadPolicy` — agent scoping via `relation_scope`
- `AgentPolicy` — agents can edit their own profile
- `AccountPolicy` — owner-only for settings/billing

Authorization context provides `user` (via `Current.user`) and `account` (via `Current.account`). Policies check `user.can_manage?(account)`, `user.owner_of?(account)`, etc.

### Database

- PostgreSQL with `t.timestamps` placed first in all `create_table` blocks
- Migrations follow the timestamps-first convention (see `.claude/standards/database/migrations.md`)
- Seeds use FactoryBot factories and are always idempotent (see `.claude/standards/database/seeds.md`)

## Frontend

- **Tailwind CSS v4** with **DaisyUI v5** loaded via `@plugin "daisyui"` in `app/assets/tailwind/application.css`
- Use DaisyUI semantic classes for UI components (`btn btn-primary`, `input input-bordered`, `card`, `alert`, etc.)
- Use raw Tailwind utilities for layout and spacing (`flex`, `grid`, `mt-4`, `p-6`)
- Theme: `data-theme="light"` on the `<html>` tag
- See `.claude/standards/frontend/daisyui-tailwind.md` for the full component class reference

## Standards

This project follows documented standards in `.claude/standards/`. See `.claude/standards/index.yml` for the full index.

| Standard | File | Summary |
|----------|------|---------|
| Database Migrations | `.claude/standards/database/migrations.md` | Place `t.timestamps` first in all `create_table` blocks |
| Seed Data | `.claude/standards/database/seeds.md` | Update seeds for every new model; use FactoryBot; always idempotent |
| TDD | `.claude/standards/testing/tdd.md` | Write failing spec before implementing (red-green cycle) |
| Commit Cadence | `.claude/standards/git/commit-cadence.md` | Commit after every significant step; RED and GREEN are separate commits |
| DaisyUI + Tailwind | `.claude/standards/frontend/daisyui-tailwind.md` | Use DaisyUI v5 component classes; installed via @plugin in Tailwind CSS |
| Makefile | `.claude/standards/tooling/makefile.md` | Use make targets instead of raw docker compose commands |
| Security & Environment | `.claude/standards/security/environment.md` | CSP, parameter filtering, env vars, rate limiting, HTTPS |
| Code Organization | `.claude/standards/code-organization/patterns.md` | Thin controllers, concerns, service objects, naming, tenant scoping |
| File Structure | `.claude/standards/code-organization/file-structure.md` | Canonical ordering for models, controllers, routes, policies, specs, factories, Gemfile |
| Error Handling | `.claude/standards/error-handling/conventions.md` | Flash messages, rescue_from, form validation, logging, error pages |
| Work Lifecycle | `.claude/standards/git/work-lifecycle.md` | Promote plan, update roadmap/docs before and after every feature |

## Coding Conventions

- **Thin controllers** — Controllers handle HTTP concerns only (params, redirects, status codes). Business logic lives in models or service objects.
- **Action Policy for authorization** — Every mutating controller action calls `authorize!`. Index actions use `authorized_scope`. Policy classes in `app/policies/`.
- **Concerns for shared behavior** — Use `ActiveSupport::Concern` in `app/models/concerns/` and `app/controllers/concerns/` for reusable behavior.
- **Service objects for complex logic** — POROs in `app/services/` with a single `call` method for operations spanning multiple models.
- **Follow Rails omakase style** — RuboCop is configured with `rubocop-rails-omakase`, `rubocop-rspec`, `rubocop-rspec_rails`, `rubocop-factory_bot`, and `rubocop-capybara`. Run `make lint` before committing.
- **Multi-tenant scoping** — Always scope queries through `Current.account` to prevent cross-tenant data access.
- **Flash messages** — Use `flash[:notice]` for success, `flash[:alert]` for errors. Display with DaisyUI alert components.
- **Form errors** — Re-render with `status: :unprocessable_content` for Turbo compatibility. Display errors inline with `model.errors`.
