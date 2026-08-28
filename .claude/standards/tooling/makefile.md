# Standard: Use Makefile Commands

## Rule

Always use `make` targets instead of raw `docker compose exec` commands. The project `Makefile` wraps all common development commands with short aliases.

## Available Targets

| Command | What it runs |
|---------|-------------|
| `make test` | Full test suite (`rspec --format documentation`) |
| `make test-file FILE=path` | Single spec file |
| `make lint` | RuboCop check |
| `make lint-fix` | RuboCop auto-fix |
| `make migrate` | `rails db:migrate` |
| `make seed` | `rails db:seed` |
| `make db-reset` | `rails db:reset` |
| `make generate ARGS="..."` | `rails generate` |
| `make console` | `rails console` |
| `make routes` | `rails routes` |
| `make up` | `docker compose up` |
| `make down` | `docker compose down` |
| `make build` | `docker compose build` |
| `make restart` | `docker compose restart` |
| `make logs` | `docker compose logs -f web` |

## Why

- Shorter commands reduce typos and friction
- Consistent environment flags (`RAILS_ENV=test`) are baked in
- New developers don't need to memorize Docker incantations
- Single source of truth for how commands are run

## Applies To

All development commands — testing, linting, migrations, generators, and Docker lifecycle. If a `make` target exists for what you need, use it.
