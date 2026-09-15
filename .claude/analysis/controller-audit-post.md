# Analysis: Controller Post-Audit

## Comparison: Before → After

Scored against the same 10-category checklist from the original
audit. Changes reflect work done in PRs #60 (P0/P1) and the
current P2 branch.

---

## Scorecard

| Category | Before | After | Delta | Key Changes |
|----------|:------:|:-----:|:-----:|-------------|
| 1. Controller Structure | 4 | 5 | +1 | Ads::BaseController extracts shared flow, HoneypotProtection concern |
| 2. Multi-Tenant Scoping | 5 | 5 | — | Already strong, unchanged |
| 3. Authorization | 4 | 5 | +1 | ScreenContentsController authorizes built instance, PairingsController adds authorize! |
| 4. Error Handling | 3 | 4 | +1 | API rescue_from for 404/422/400, render_error helper |
| 5. Parameter Handling | 3 | 5 | +2 | ScreenContentsController uses strong params, type validation via delegated_type |
| 6. Routing | 3 | 4 | +1 | API versioned under /v1/, namespace structure |
| 7. Security | 4 | 5 | +1 | Rate limiting on API + Go::Leads, no integer ID leaks |
| 8. API Controllers | 2 | 4 | +2 | Versioning, response envelope, error handlers, rate limits, V1::BaseController |
| 9. Performance | 3 | 3 | — | No changes yet (strict loading, Bullet deferred to follow-up) |
| 10. Testing | 4 | 5 | +1 | Cross-tenant isolation specs on all 8 main resources, service specs |
| **Overall** | **3.5** | **4.5** | **+1.0** | |

---

## What Was Fixed

### P0 (Security — all done)

| Issue | Resolution |
|-------|-----------|
| ScreenContentsController: no strong params, no type validation | Strong params + `delegated_type` validates type + authorize built instance |
| ScreenContentsController: `destroy_all` wipes analytics history | `AssignScreenContent` service deactivates old, creates new |
| API: no error handlers for RecordNotFound/RecordInvalid | `rescue_from` in `Api::BaseController` returns JSON |
| API: no rate limiting | 60 req/min baseline, 10 req/min on registration |
| Go::LeadsController: no rate limiting | 10 req/hr per IP |

### P1 (Best Practices — all done)

| Issue | Resolution |
|-------|-----------|
| API unversioned | All routes under `/v1/`, `Api::V1::BaseController` |
| API inconsistent response format | `render_data` / `render_error` helpers, `{ data: ... }` / `{ error: { message: ... } }` |
| PairingsController: `find_by(id:)`, no authorize! | `find_by_param!` + `authorize! screen, to: :update?` |
| Pairing logic in model | `PairPlayerToScreen` service, `pair_player!` moved to test helper |
| Lead capture inline in controller | `CaptureLead` service |
| API players show leaks `screen_id` integer | Removed from response |
| No cross-tenant isolation specs | Shared example on all 8 main resources |

### P2 (Improvements — done)

| Issue | Resolution |
|-------|-----------|
| 4 ad controllers duplicate build/validate/save | `App::Ads::BaseController` extracts flow, children are 9-23 lines |
| Honeypot logic duplicated in 2 controllers | `HoneypotProtection` concern |

### Phase 4 (Standard — done)

| Issue | Resolution |
|-------|-----------|
| No documented controller conventions | `.claude/standards/controllers/conventions.md` |

---

## What Remains (Deferred to Follow-Up)

| Issue | Priority | Effort |
|-------|----------|--------|
| Route `:only` cleanup | Low | Small |
| Strict loading in development | Low | Small |
| Bullet gem for N+1 detection | Low | Small |
| I18n flash messages (some hardcoded) | Low | Small |
| DashboardPresenter (fat controller) | Low | Medium |
| BrandAd architecture (should it be a delegated type?) | Medium | Medium |
| Performance (N+1, includes) | Medium | Medium |

None of these are security issues. They're housekeeping improvements
that can be addressed incrementally.

---

## Service Objects Introduced

| Service | Lines | Replaces |
|---------|:-----:|----------|
| `AssignScreenContent` | 12 | Inline destroy_all + create in controller |
| `PairPlayerToScreen` | 30 | `Screen#pair_player!` model method + controller validation |
| `CaptureLead` | 25 | Inline signed ID resolution + lead creation in controller |

Total: 3 services, 67 lines. Each is independently testable with
its own spec in `spec/services/`.

---

## Controller-by-Controller Re-Score

| Controller | Before | After | Changes |
|------------|:------:|:-----:|---------|
| App::ScreenContentsController | 2 | 5 | Strong params, type validation, authorize instance, service |
| App::ScreenPlayersController | 3 | 5 | Delegates to PairPlayerToScreen service |
| App::PairingsController | 3 | 5 | find_by_param!, authorize!, service |
| App::Ads::ListingAdsController | 4 | 5 | Inherits from Ads::BaseController (16 lines) |
| App::Ads::AgentAdsController | 4 | 5 | Inherits from Ads::BaseController (13 lines) |
| App::Ads::BrandAdsController | 4 | 5 | Inherits from Ads::BaseController (9 lines) |
| App::Ads::CollectionAdsController | 4 | 5 | Inherits from Ads::BaseController (23 lines) |
| Go::LeadsController | 4 | 5 | CaptureLead service, HoneypotProtection concern, rate limit |
| Api::PlayersController | 3 | 4 | Versioned, envelope, rate limit |
| Api::Players::HeartbeatsController | 3 | 4 | Versioned, envelope, 204 response |
| Api::Players::ManifestsController | 4 | 5 | Versioned, error handling |
| Api::Players::PairingCodesController | 3 | 4 | Versioned, envelope |
| Marketing::InquiriesController | 4 | 5 | HoneypotProtection concern |
| App::DashboardController | 3 | 3 | Unchanged (DashboardPresenter deferred) |

---

## Test Coverage

| Metric | Before | After |
|--------|:------:|:-----:|
| Total examples | 1134 | 1152 |
| New service specs | 0 | 3 (22 examples) |
| Tenant isolation specs | 11 resources | 19 resources |
| API error specs | 0 | 3 |

---

## Summary

The codebase moved from **3.5/5 to 4.5/5**. The critical gaps
(parameter injection, missing error handlers, no rate limiting,
no API versioning) are all resolved. The remaining items are
quality-of-life improvements, not security or correctness issues.

The controller standard ensures new controllers follow these
patterns from day one.
