# Plan: Code Quality Audit — Close Testing & Tooling Gaps

## Context

Audit revealed gaps in test coverage (missing policy/service specs, low React test ratio), no error tracking in production, and missing safety tooling (strong_migrations). This plan addresses all gaps in priority order.

---

## Phase 1: Missing Rails specs (low effort, high coverage impact)

### Policy specs (9 missing)

Add specs for: `AdPolicy`, `ListingAgentPolicy`, `PlaylistAdPolicy`, `PlaylistPolicy`, `QrCodePolicy`, `ScreenContentPolicy`, `ScreenPlayerPolicy`, `SettingsPolicy`, `SitePolicy`.

Each follows the existing pattern — `permit`/`forbid` matchers per role:
```ruby
it { is_expected.to permit_actions(:show, :update).to(:manager) }
it { is_expected.to forbid_actions(:destroy).to(:agent) }
```

### Service specs (2 missing)

- `spec/services/record_heartbeat_spec.rb` — test it updates player fields (screen_width, screen_height, user_agent)
- `spec/services/refresh_pairing_code_spec.rb` — test it generates a new code and sets expiry

### Files
- Create: 9 policy specs in `spec/policies/`
- Create: 2 service specs in `spec/services/`

---

## Phase 2: strong_migrations

Add the gem to prevent unsafe migrations in production (adding columns with defaults on large tables, removing columns, etc.).

```ruby
# Gemfile
gem "strong_migrations"
```

```bash
bundle install
bin/rails generate strong_migrations:install
```

Creates `config/initializers/strong_migrations.rb` with safe defaults. Zero impact on existing migrations — only validates new ones.

### Files
- Modify: `Gemfile`
- Create: `config/initializers/strong_migrations.rb`

---

## Phase 3: Error tracking (Sentry)

Add Sentry for error tracking in production and staging. Rails + React player.

### Rails
```ruby
# Gemfile
gem "sentry-ruby"
gem "sentry-rails"
```

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.traces_sample_rate = 0.1
  config.environment = Rails.env
end
```

### React player
```bash
cd player-app && npm install @sentry/react
```

```typescript
// src/main.tsx
import * as Sentry from "@sentry/react"
Sentry.init({ dsn: import.meta.env.VITE_SENTRY_DSN, environment: ... })
```

### Environment
- Add `SENTRY_DSN` to staging and production env vars (Render)
- Add `VITE_SENTRY_DSN` to player-app env vars (Cloudflare Pages)

### Files
- Modify: `Gemfile`
- Create: `config/initializers/sentry.rb`
- Modify: `player-app/package.json`
- Modify: `player-app/src/main.tsx`
- Modify: `player-app/src/preview.tsx` (optional — preview errors)

---

## Phase 4: React composition tests

The 8 listing ad compositions and 8 elements have zero tests. They're primarily visual, so Storybook interaction tests via `@storybook/addon-vitest` are more valuable than unit tests. But basic render tests ensure they don't crash.

### Element tests (7 files)
For each element (Badge, Price, Address, Specs, AgentStrip, QrCode, PhotoWrap): verify it renders with valid props and handles null/missing data gracefully.

### Composition smoke tests (8 files)
For each layout × aspect: verify it renders without crashing given a mock ad. Not testing visual output — that's Storybook's job.

### Files
- Create: 7 test files in `player-app/src/components/ads/elements/*/`
- Create: 8 test files in `player-app/src/components/ads/listings/*/`

---

## Phase 5: TypeScript strict mode

Enable stricter TypeScript checks incrementally.

### Step 1: Enable `strict: true` in `tsconfig.app.json`
This turns on: `strictNullChecks`, `strictFunctionTypes`, `strictBindCallApply`, `noImplicitAny`, `noImplicitThis`.

### Step 2: Fix errors
Most will be null checks on optional fields (`listing.beds` used without `?? 0`). The compositions already handle nulls via the elements, so the fix count should be manageable.

### Files
- Modify: `player-app/tsconfig.app.json`
- Modify: various component files as needed for type fixes

---

## Phase 6: GitHub Actions CI

No CI pipeline exists. PRs merge without automated checks.

### Workflow: `.github/workflows/ci.yml`

Two jobs — Rails and Player — run in parallel on every PR and push to main/staging.

**Rails job:**
```yaml
- Checkout
- Setup Ruby (bundler cache)
- Setup Postgres service
- bundle install
- RuboCop lint
- Brakeman security scan
- bundler-audit
- db:schema:load + rspec
```

**Player job:**
```yaml
- Checkout
- Setup Node (npm cache)
- npm ci
- oxlint (lint)
- tsc --noEmit (type check)
- vitest run (tests)
- vite build (verify production build)
```

### Files
- Create: `.github/workflows/ci.yml`

---

## Phase 7: Prettier for formatting

No formatting tool — code style drifts across files. Add Prettier for consistent formatting.

### Setup
```bash
cd player-app
npm install -D prettier
```

### Config: `player-app/.prettierrc`
```json
{
  "semi": false,
  "singleQuote": false,
  "trailingComma": "all",
  "printWidth": 120
}
```

Match the existing code style (no semicolons based on current files, double quotes for JSX).

### Scripts
Add to `package.json`:
```json
"format": "prettier --write src/",
"format:check": "prettier --check src/"
```

Run `format:check` in CI, `format` locally before commits.

### Files
- Modify: `player-app/package.json`
- Create: `player-app/.prettierrc`

---

## Phase 8: Fix oxlint warnings

5 exhaustive-deps warnings in PlayerShell. Fix or suppress with documented reasons.

### Files
- Modify: `player-app/src/components/PlayerShell/index.tsx`

---

## Execution order

| Phase | What | Effort | Impact |
|-------|------|--------|--------|
| 1 | Missing Rails specs | ~1 hour | Closes coverage gaps, SimpleCov stays green |
| 2 | strong_migrations | 5 min | Prevents unsafe migrations |
| 3 | Sentry | 30 min | Production error visibility |
| 4 | React composition tests | ~1 hour | Prevents silent render crashes |
| 5 | TypeScript strict | ~1 hour | Catches null/type bugs at compile time |
| 6 | GitHub Actions CI | 30 min | Automated checks on every PR |
| 7 | Prettier | 15 min | Consistent formatting |
| 8 | Fix oxlint warnings | 15 min | Clean lint output |

## Verification

- Phase 1: `make test` — all specs pass, coverage stays above thresholds
- Phase 2: `make test` — strong_migrations initializer loads
- Phase 3: Deploy to staging, trigger an error, verify it appears in Sentry
- Phase 4: `npx vitest run` — all React tests pass
- Phase 5: `npm run build` — TypeScript compiles with strict mode
- Phase 6: Push a PR — CI runs green
- Phase 7: `npm run format:check` — no formatting issues
- Phase 8: `npm run lint` — zero warnings
