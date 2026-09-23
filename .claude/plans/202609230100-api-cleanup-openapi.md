# Plan: API Cleanup + OpenAPI Docs

**Created:** 2026-09-22
**Status:** Draft
**Branch:** TBD
**Depends on:** Consolidate API under Play subdomain

## Problem

The API has inconsistencies (envelope, rate limits, error shapes)
and no machine-readable documentation. The `api.` subdomain is now
empty after consolidation and should be removed.

## Part 1: Drop API Subdomain (code only — DNS deferred)

Remove the API subdomain from the codebase. DNS record removal
(`api.replaytv.co`, `api.replaytv.dev`) is deferred to a separate
infrastructure task.

### Routes
- Remove the empty `constraints subdomain: "api"` block (if any remains)
- API routes already live under Play from the consolidation plan

### Code
- Remove `api.replay.localhost` references from specs
- Update `docs/architecture/subdomains.md` — 4 subdomains, not 5
- Update any hardcoded API host references

### Deferred
- DNS: Remove `api.replaytv.co` and `api.replaytv.dev` records (OpenTofu)

## Part 2: API Consistency

### Response envelope

All API endpoints should use the same envelope:

**Success:**
```json
{ "data": { ... } }
```

**Error:**
```json
{ "error": { "message": "..." } }
```

Currently `render_data` in `Play::Api::V1::BaseController` handles this.
Verify all endpoints use it consistently.

### Error responses

| Status | When | Body |
|--------|------|------|
| 401 | Invalid/missing session | `{ error: { message: "Invalid session" } }` |
| 404 | Record not found | `{ error: { message: "Not found" } }` |
| 410 | Player unpaired | `{ error: { message: "unpaired" } }` |
| 422 | Validation error | `{ error: { message: "..." } }` |
| 429 | Rate limited | Standard Rails rate limit response |

### Rate limits

| Endpoint | Limit |
|----------|-------|
| `POST /api/v1/players` (registration) | 10/IP/min |
| All authenticated endpoints | 60/IP/min (global) |

Verify Play subdomain inherits the API rate limits for the
`/api/v1/*` routes.

## Part 3: Bearer Auth for Native Apps

Add bearer token support to `PlayerAuthentication` concern as a
fallback for native apps that can't use cookies:

```ruby
def resume_player_session
  return @current_player_session if defined?(@current_player_session)

  @current_player_session =
    find_session_from_bearer ||
    find_session_from_cookie

  @current_player = @current_player_session&.player
  @current_player_session
end

def find_session_from_bearer
  if token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    PlayerSession.active.find_by(token: token)
  end
end

def find_session_from_cookie
  PlayerSession.active.find_by(id: cookies.signed[:player_session_id])
end
```

This requires adding a `token` column to `PlayerSession` —
generated on create, used only for bearer auth. The signed cookie
ID remains the primary auth for browser players.

## Part 4: OpenAPI Documentation

### Setup

Add to Gemfile (test group):
```ruby
gem "rspec-openapi"
gem "committee"
gem "committee-rails"
```

### Generate spec

`rspec-openapi` auto-generates `openapi.yaml` from request specs.
Run `OPENAPI=1 make test` to regenerate.

Configure in `spec/rails_helper.rb`:
```ruby
RSpec::OpenAPI.path = "docs/api/openapi.yaml"
RSpec::OpenAPI.title = "RePlay Player API"
RSpec::OpenAPI.servers = [
  { url: "https://play.replaytv.co", description: "Production" }
]
```

### Validate responses

Add `committee` assertions to API request specs:
```ruby
# In spec/support/api_schema_validation.rb
RSpec.configure do |config|
  config.include Committee::Rails::Test::Methods, type: :request
  config.add_setting :committee_options
  config.committee_options = {
    schema_path: "docs/api/openapi.yaml"
  }
end
```

### Browsable UI

Serve Swagger UI at `play.replaytv.co/api/docs`:

```ruby
# config/routes.rb (inside Play constraints)
get "/api/docs", to: redirect("/api/docs/index.html")
```

With a static HTML file loading Swagger UI from CDN pointing
at `/api/openapi.yaml`.

### What gets documented

| Endpoint | Description |
|----------|-------------|
| `POST /api/v1/players` | Register a new player device |
| `GET /api/v1/player` | Player status (paired/unpaired) |
| `POST /api/v1/player/heartbeat` | Device heartbeat |
| `GET /api/v1/player/manifest` | Content manifest with ETag |
| `POST /api/v1/player/pairing_code` | Refresh pairing code |

5 endpoints. Clean, small surface area.

## Execution

### Step 1 — Drop API subdomain
- Remove routes, DNS references, spec host overrides
- Update subdomains doc

### Step 2 — Fix API response consistency
- Audit all render calls for envelope compliance
- Fix any bare `render json:` in API controllers

### Step 3 — Add bearer auth to PlayerSession (TDD)
- Migration: add `token` column to `player_sessions`
- Update `PlayerAuthentication` to check bearer first
- Specs for bearer + cookie auth

### Step 4 — Setup rspec-openapi + committee
- Add gems, configure
- Generate initial openapi.yaml
- Add response validation to API specs

### Step 5 — Serve Swagger UI
- Static HTML page at `/api/docs`
- Mount openapi.yaml as a static asset

### Step 6 — Ship
- `make lint`, `make test`
- Update docs, CLAUDE.md
- Push, create PR
