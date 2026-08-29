# Contributing

How we write code, test, and ship features in RePlay.

## Setup

```bash
git clone git@github.com:omarvelous/replay-rails.git
cd replay-rails
make build && make up && make migrate && make seed
```

See [onboarding.md](onboarding.md) for full setup details and demo credentials.

## Workflow

Every feature follows a consistent lifecycle:

### 1. Plan

- Check `.claude/plans/drafts/` for an existing draft, or create one
- Discuss scope and approach before writing code

### 2. Branch

```bash
git checkout main && git pull
git checkout -b feature-name
```

### 3. Promote the plan

- Move from `drafts/` to `.claude/plans/` with a timestamp prefix (e.g., `202608281700-feature-name.md`)
- Update `.claude/product/roadmap.md` — mark as "In progress"
- Commit as the first commit on the branch

### 4. Build (TDD)

- **Red** — write a failing spec, run it, confirm it fails
- **Green** — write the minimum code to make it pass
- **Red and green are separate commits**

```
RED:   Add spec for lead assignment
GREEN: Implement lead assignment
```

### 5. Ship

Before creating a PR:

- Update roadmap (mark as shipped)
- Update developer docs if architecture/API changed (`docs/`)
- Update CLAUDE.md if conventions changed
- Update user docs if behavior changed (`app/views/docs/pages/`)
- Run `make lint` and `make test`
- Push and create PR

## File structure conventions

We follow canonical ordering within files. This keeps the codebase scannable and consistent.

### Models

```
1. Includes / extends
2. Gem macros (acts_as_tenant, has_paper_trail)
3. Constants
4. Enums / store accessors
5. Associations (belongs_to → has_one → has_many → :through)
6. Attachments
7. Delegations
8. Validations
9. Scopes
10. Callbacks
11. Class methods
12. Instance methods
13. Private methods
```

### Controllers

```
1. Filters (before_action)
2. Actions in REST order: index, show, new, create, edit, update, destroy
3. Custom actions (preview, export)

private:
4. Setters (set_listing)
5. Params (listing_params)
6. Helpers
```

### Routes

- Subdomain blocks have section headers
- Resources grouped by domain concept: Content, Playback, Engagement, Team
- Nested resources indented under parent

### Policies

```
1. Read permissions (index?, show?)
2. Write permissions (create?, update?, destroy?)
3. Scopes
4. Private helpers
```

### Specs

```
1. Subject
2. let declarations (dependencies → records)
3. describe "associations"
4. describe "validations"
5. describe ".class_method"
6. describe "#instance_method"
```

### Factories

```
1. Required associations
2. Required attributes
3. Optional attributes
4. Traits
```

### Gemfile

- Grouped by purpose (Framework, Database, Frontend, Auth, Content, Admin, API, Infrastructure)
- Alphabetical within each group
- Group blocks at the bottom: `:development, :test` → `:development` → `:test`

See `.claude/standards/code-organization/file-structure.md` for the full reference with examples.

## Commands

All development goes through the Makefile:

| Command | What it does |
|---------|-------------|
| `make test` | Run full RSpec suite |
| `make test-file FILE=path` | Run a single spec |
| `make lint` | Check for RuboCop offenses |
| `make lint-fix` | Auto-fix offenses |
| `make migrate` | Run migrations |
| `make seed` | Seed demo data |
| `make db-reset` | Drop, create, migrate, seed |
| `make console` | Rails console |
| `make routes` | Display all routes |
| `make logs` | Tail web logs |

Do not use raw `docker compose exec` commands.

## Multi-tenancy

All tenant-scoped models use `acts_as_tenant :account`. Queries are automatically filtered when a tenant is set (authenticated app controllers). For cross-tenant access:

```ruby
ActsAsTenant.without_tenant { Listing.all }     # Admin, seeds
ActsAsTenant.with_tenant(account) { ... }       # Background jobs
```

## Authorization

Action Policy with two contexts (`user` and `account`). Every mutating action calls `authorize!`. Index actions use `authorized_scope`.

Three roles: **owner** (full access), **manager** (CRUD + invite agents), **agent** (own listings/leads only).

## Testing expectations

- 95%+ line coverage, 80%+ branch coverage
- Every feature has request specs
- Authorization tested for all three roles
- Factories in `spec/factories/`, realistic data via Faker
- `make lint` passes before every PR

## Where things live

| What | Where |
|------|-------|
| Coding standards | `.claude/standards/` |
| Implementation plans | `.claude/plans/` |
| Draft plans | `.claude/plans/drafts/` |
| Product context | `.claude/product/` (roadmap, mission, tech stack) |
| Developer docs | `docs/` |
| User-facing docs | `app/views/docs/pages/` |
| Docs manifest | `config/docs.yml` |
