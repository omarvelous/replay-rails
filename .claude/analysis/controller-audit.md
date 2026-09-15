# Analysis: Controller Audit

## Methodology

Scored every controller against a 10-category checklist derived from
Rails 8 best practices, OWASP guidelines, multi-tenant SaaS patterns,
and the Rails omakase style guide. Each category is scored 1-5:

- **5** — Fully compliant, no issues
- **4** — Minor gaps, low risk
- **3** — Notable gaps, should fix
- **2** — Significant issues, fix soon
- **1** — Critical issues, fix immediately

---

## Scorecard

| Category | Score | Summary |
|----------|:-----:|---------|
| 1. Controller Structure | 4 | Clean hierarchy, good separation. A few fat actions. |
| 2. Multi-Tenant Scoping | 5 | Solid. acts_as_tenant + explicit Current.account scoping. |
| 3. Authorization | 4 | Consistent ActionPolicy usage. A few gaps in nested controllers. |
| 4. Error Handling | 3 | HTML side is good. API side lacks structured error responses. |
| 5. Parameter Handling | 3 | Most controllers good. ScreenContentsController skips strong params. |
| 6. Routing | 3 | Well-organized subdomains. No API versioning. Some over-generated routes. |
| 7. Security | 4 | CSRF, tenant isolation, signed IDs all solid. Missing rate limits on API. |
| 8. API Controllers | 2 | No versioning, inconsistent response format, no pagination, no error handler. |
| 9. Performance | 3 | Good use of includes in some places. Missing pagination on some indexes. N+1 risks. |
| 10. Testing | 4 | Good request spec coverage. Missing cross-tenant isolation tests. |
| **Overall** | **3.5** | Strong foundation, specific gaps to close. |

---

## Category Details

### 1. Controller Structure — Score: 4

**What's working:**
- Clean inheritance hierarchy: `ApplicationController` → `App::BaseController` → individual controllers
- Separate base controllers for each namespace (App, API, Admin, Marketing, Play)
- Consistent `set_*` / `*_params` private method pattern
- Concerns used for shared behavior (`Authentication`)

**Issues found:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| Dashboard controller has ~20 lines of analytics queries | Low | `app/dashboards_controller.rb` | Extract to `DashboardPresenter` or query object |
| ScreenPlayersController has complex validation logic with multiple early returns | Low | `app/screen_players_controller.rb` | Extract pairing validation to a service object or form object |
| ScreenContentsController does `destroy_all` + `create` in one action | Low | `app/screen_contents_controller.rb` | Could be a `ReplaceScreenContent` service, but acceptable for now |
| Ads type controllers duplicate the dual-model save pattern | Low | `app/ads/*.rb` (4 controllers) | Could extract to `CreateTypedAd` service. Not urgent — the pattern is consistent. |
| Honeypot check duplicated in Go::LeadsController and Marketing::InquiriesController | Low | Two controllers | Extract to a `HoneypotProtection` concern |

### 2. Multi-Tenant Scoping — Score: 5

**What's working:**
- `set_current_tenant_through_filter` in ApplicationController
- Every App controller scopes through `Current.account.model`
- Admin explicitly uses `without_tenant` around_action
- Public controllers (Go) properly skip auth and don't touch `Current.account`
- API controllers use token auth with no tenant assumption

**No issues found.** This is the strongest area of the codebase.

### 3. Authorization — Score: 4

**What's working:**
- ActionPolicy context set up once in `App::BaseController`
- `authorize!` called consistently in show/edit/update/destroy actions
- `authorized_scope` used in index actions
- `rescue_from ActionPolicy::Unauthorized` in base controller
- Policy classes exist for every model with a controller

**Issues found:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| ScreenContentsController `create` doesn't authorize the contentable being assigned | Medium | `app/screen_contents_controller.rb` | Verify user can access the playlist/experience being assigned, not just the screen |
| QrScansController authorizes `@qr_code` with `to: :show?` — technically correct but implicit | Low | `app/qr_scans_controller.rb` | Fine as-is, just document the intent |
| PairingsController doesn't call `authorize!` on the screen being paired | Medium | `app/pairings_controller.rb` | Add `authorize! @screen` before pairing |

### 4. Error Handling — Score: 3

**What's working:**
- HTML controllers consistently re-render with `status: :unprocessable_entity`
- ActionPolicy::Unauthorized rescued in App::BaseController
- Password reset handles InvalidSignature gracefully
- Flash messages use `notice` and `alert` consistently

**Issues found:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| API BaseController has no `rescue_from ActiveRecord::RecordNotFound` | High | `api/base_controller.rb` | Add rescue returning `{ error: "Not found" }` with 404 |
| API BaseController has no `rescue_from ActionController::ParameterMissing` | Medium | `api/base_controller.rb` | Add rescue returning `{ error: "Bad request" }` with 400 |
| API returns bare hashes like `{ error: "Unauthorized" }` — no consistent envelope | Medium | All API controllers | Standardize on `{ error: { message: "...", code: "..." } }` |
| No catch-all error handler for unexpected exceptions in API | Medium | `api/base_controller.rb` | Add `rescue_from StandardError` (production only) returning 500 JSON |
| Flash messages use hardcoded English strings instead of I18n keys in some places | Low | Various App controllers | Convert `notice: "Lead updated."` to `notice: t(".success")` — some already do this |
| Go::LeadsController silently returns `head :ok` for honeypot — attacker can't distinguish from success | Low | `go/leads_controller.rb` | Fine for security, but log honeypot hits for monitoring |

### 5. Parameter Handling — Score: 3

**What's working:**
- Strong params used in most controllers with explicit permit lists
- No `params.permit!` or `params.to_unsafe_h` anywhere
- Sensitive fields not permitted (no `account_id`, `user_id` in permit lists)

**Issues found:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| ScreenContentsController reads `params[:contentable_type]` and `params[:contentable_id]` directly — no strong params | High | `app/screen_contents_controller.rb` | Wrap in `screen_content_params.permit(:contentable_type, :contentable_id)` and validate `contentable_type` is in allowlist |
| `contentable_type` is user-controlled and used in a polymorphic lookup — type injection risk | High | Same | Validate `contentable_type.in?(%w[Playlist Experience])` before using |
| ScreenPlayersController reads `params[:code]` directly | Low | `app/screen_players_controller.rb` | Acceptable for a simple string value, but could use strong params for consistency |
| Screens create action reads `params[:screen][:site_id]` for site lookup — if user sends a valid UUID for another tenant's site, acts_as_tenant blocks it, but explicit validation is better | Low | `app/screens_controller.rb` | Already scoped via `Current.account.sites.find_by_param!` — safe |

### 6. Routing — Score: 3

**What's working:**
- Clear subdomain-based namespace separation (marketing, app, admin, api, play)
- Nested resources are max 1 level deep (listings/listing_agents, playlists/playlist_ads)
- Custom actions use `member` routes (`preview` on ads/playlists)
- Root routes defined for each subdomain

**Issues found:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| API routes are unversioned (`/api/players/` not `/api/v1/players/`) | Medium | `config/routes.rb` | Wrap in `namespace :v1` now, before any external consumers depend on the paths |
| Some `resources` declarations generate all 7 routes when fewer are used | Low | Various | Add `:only` filters. E.g., `resources :qr_codes, only: [:index, :show]` |
| Admin routes generate full CRUD for all resources via Administrate | Low | Admin namespace | Acceptable — Administrate manages this |
| Pairing has two entry points (ScreenPlayersController and PairingsController) for similar flows | Low | Routes | Intentional — different UX flows (screen-initiated vs user-initiated) |

### 7. Security — Score: 4

**What's working:**
- CSRF protection active on all HTML controllers
- API uses `null_session` (correct for token auth)
- `allow_browser versions: :modern` set
- Sequential IDs replaced with UUIDs (public_id migration)
- Signed IDs on lead form hidden fields
- Honeypot fields on public forms
- Rack::Attack configured for throttling
- Session cookies configured with httponly, samesite
- Admin on separate subdomain with role gate

**Issues found:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| API endpoints have no rate limiting | High | `api/base_controller.rb` | Add `rate_limit` to player registration and heartbeat |
| Sessions controller rate limits (10/3min) but passwords controller may need tighter limits | Medium | `passwords_controller.rb` | Already has rate_limit — verify it's tight enough |
| No rate limiting on Go::LeadsController | Medium | `go/leads_controller.rb` | Add Rack::Attack throttle for `POST /go/leads` per IP |
| `redirect_to destination, allow_other_host: true` in ScansController — open redirect via QR destination_url | Low | `scans_controller.rb` | Acceptable — QR destinations are admin-configured, not user-input. But validate URL format on QR code creation. |

### 8. API Controllers — Score: 2

This is the weakest area. The API works but doesn't follow REST best practices.

**What's working:**
- Token authentication via player tokens
- Jbuilder for manifest serialization
- ETag caching on manifest endpoint
- Consistent token-based routing (`param: :token`)

**Issues found:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| No API versioning | High | Routes + controllers | Add `/api/v1/` namespace |
| No `rescue_from` for common exceptions (RecordNotFound, ParameterMissing) | High | `api/base_controller.rb` | Add JSON error handlers |
| Inconsistent response format — some return `{ paired: true }`, some return `{ error: "..." }` | Medium | Various API controllers | Standardize envelope: `{ data: ... }` or `{ error: ... }` |
| Player `create` returns `pairing_code` and `token` as top-level keys, not nested under `data` | Medium | `api/players_controller.rb` | Wrap in `{ data: { token: ..., pairing_code: ... } }` |
| Heartbeat returns `{ ok: true }` — not a standard REST response | Low | `api/players/heartbeats_controller.rb` | Return 204 No Content instead of a body |
| No pagination on any API endpoint (currently none need it, but no infrastructure exists) | Low | N/A | Add when needed |
| No API documentation (OpenAPI/Swagger) | Low | N/A | Not urgent but valuable for the Android player team |

### 9. Performance — Score: 3

**What's working:**
- Pagy pagination on most index actions
- `includes` used in several controllers (listings with agents, playlists with ads)
- ETag caching on manifest endpoint
- Counter-style queries for dashboard stats

**Issues found:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| QrCodesController index loads `includes(:destination_record)` — polymorphic includes can be inefficient | Low | `app/qr_codes_controller.rb` | Monitor query count, consider separate queries per type |
| ScreensController show runs 3 separate analytics queries (impressions, scans, chart data) | Medium | `app/screens_controller.rb` | Consider caching or moving to a presenter |
| DashboardController runs ~8 separate queries for stats | Medium | `app/dashboards_controller.rb` | Cache with `Rails.cache.fetch` or use rollup data |
| Some index actions don't have `includes` for associations rendered in views | Medium | Various | Add `includes` to prevent N+1 in views that render associations (e.g., listing cards showing agents) |
| No `strict_loading` configured to catch N+1 in development | Low | Models | Add `self.strict_loading_by_default = true` in development |
| Ads index loads all ads then filters — no scope-level filtering for ad_type | Low | `app/ads_controller.rb` | Already uses `.where(adable_type:)` when filtered — fine |

### 10. Testing — Score: 4

**What's working:**
- Request specs for all controller namespaces
- Policy specs with role-based testing
- Analytics event specs with shared examples
- Factory Bot with traits
- Tenant isolation tested implicitly (scoped finds)

**Issues found:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| No explicit cross-tenant isolation tests | Medium | Request specs | Add specs: "Account B user cannot see Account A's listings" |
| No unauthorized access specs for most actions | Medium | Various | Add specs: "agent cannot create listings" (redirect or 403) |
| No specs for API error responses (404, 401 on bad token) | Medium | `spec/requests/api/` | Some exist (401 for invalid token) but not comprehensive |
| No Bullet gem for N+1 detection in test | Low | Gemfile | Add `gem "bullet"` to test group |
| No shared examples for common patterns ("behaves like a paginated index") | Low | `spec/support/` | Would reduce spec duplication |

---

## Priority Fixes

### P0 — Fix Now (Security / Data Integrity)

| # | Issue | Effort | Where |
|---|-------|--------|-------|
| 1 | ScreenContentsController: validate `contentable_type` against allowlist | Small | `app/screen_contents_controller.rb` |
| 2 | ScreenContentsController: use strong params instead of raw `params[]` | Small | Same |
| 3 | API: add `rescue_from RecordNotFound` returning JSON 404 | Small | `api/base_controller.rb` |
| 4 | API: add rate limiting to player registration + heartbeat | Small | `api/base_controller.rb` |

### P1 — Fix Soon (Best Practice Gaps)

| # | Issue | Effort | Where |
|---|-------|--------|-------|
| 5 | API versioning: wrap routes in `namespace :v1` | Small | `config/routes.rb` + move controllers |
| 6 | API: standardize response envelope (`data`/`error`) | Medium | All API controllers + Jbuilder templates |
| 7 | API: add `rescue_from ParameterMissing` returning JSON 400 | Small | `api/base_controller.rb` |
| 8 | Add cross-tenant isolation request specs | Medium | `spec/requests/` |
| 9 | Rate limit Go::LeadsController | Small | Rack::Attack or Rails `rate_limit` |
| 10 | PairingsController: add `authorize!` on screen | Small | `app/pairings_controller.rb` |

### P2 — Improve When Convenient

| # | Issue | Effort | Where |
|---|-------|--------|-------|
| 11 | Extract honeypot check to shared concern | Small | New concern |
| 12 | Add `:only` filters to route declarations | Small | `config/routes.rb` |
| 13 | Dashboard queries → presenter or cached | Medium | `app/dashboards_controller.rb` |
| 14 | Add `strict_loading` in development | Small | Model config |
| 15 | Add Bullet gem for N+1 detection | Small | Gemfile |
| 16 | Convert hardcoded flash strings to I18n keys | Small | Various controllers |
| 17 | ScreenContentsController: authorize the contentable | Small | `app/screen_contents_controller.rb` |

---

## Controller-by-Controller Quick Reference

| Controller | Structure | Auth | Params | Errors | Notes |
|------------|:---------:|:----:|:------:|:------:|-------|
| App::ListingsController | 5 | 5 | 5 | 4 | Solid |
| App::AgentsController | 5 | 5 | 5 | 4 | Solid |
| App::AdsController | 4 | 5 | 5 | 4 | Preview action could be member route |
| App::Ads::ListingAdsController | 4 | 5 | 5 | 4 | Dual-model save pattern, works |
| App::Ads::AgentAdsController | 4 | 5 | 5 | 4 | Same pattern |
| App::Ads::BrandAdsController | 4 | 5 | 5 | 4 | Same pattern |
| App::Ads::CollectionAdsController | 4 | 5 | 5 | 4 | Same pattern |
| App::LeadsController | 5 | 5 | 5 | 4 | Clean, limited actions |
| App::PlaylistsController | 5 | 5 | 5 | 4 | Solid |
| App::PlaylistAdsController | 5 | 5 | 5 | 4 | Nested correctly |
| App::ScreensController | 4 | 5 | 4 | 4 | Multiple query params for filtering |
| App::ScreenContentsController | 2 | 3 | 1 | 4 | **Worst offender** — no strong params, no type validation |
| App::ScreenPlayersController | 3 | 4 | 3 | 4 | Complex validation inline |
| App::SitesController | 5 | 5 | 5 | 4 | Solid |
| App::ExperiencesController | 5 | 5 | 5 | 4 | Solid |
| App::QrCodesController | 5 | 5 | — | 4 | Read-only, no params needed |
| App::QrScansController | 4 | 4 | — | 4 | Auth on parent, not scan |
| App::UsersController | 5 | 5 | — | 4 | Read-only |
| App::AccountUsersController | 4 | 4 | 4 | 4 | Role assignment |
| App::InvitesController | 3 | 4 | 4 | 3 | Complex flow, many branches |
| App::PairingsController | 3 | 3 | 3 | 4 | Missing authorize!, direct params |
| App::DashboardController | 3 | 5 | — | 4 | Fat action, many queries |
| App::LeadAgentsController | 4 | 5 | 4 | 4 | Solid |
| App::ListingAgentsController | 5 | 5 | 5 | 4 | Solid |
| Go::ListingsController | 5 | — | — | 4 | Clean, public |
| Go::AgentsController | 5 | — | — | 4 | Clean, public |
| Go::ExperiencesController | 5 | — | — | 4 | Clean, public |
| Go::LeadsController | 4 | — | 4 | 4 | Signed IDs, honeypot |
| Play::PlayersController | 4 | 4 | — | 3 | Multiple render paths |
| Api::PlayersController | 3 | 3 | 3 | 2 | No error handling, no versioning |
| Api::Players::HeartbeatsController | 3 | 3 | 3 | 2 | Returns 410 but no 404 handler |
| Api::Players::ManifestsController | 4 | 3 | — | 2 | ETag caching good, error handling weak |
| Api::Players::PairingCodesController | 3 | 3 | — | 2 | No error handling |
| ScansController | 4 | — | — | 4 | Clean passthrough |
| Marketing::PagesController | 5 | — | — | — | Static pages |
| Marketing::InquiriesController | 4 | — | 4 | 4 | Honeypot, rate limited |
| Admin::ApplicationController | 4 | 5 | — | 3 | find_resource override good |
