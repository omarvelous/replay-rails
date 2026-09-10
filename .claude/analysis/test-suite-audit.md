# Test Suite Audit (September 2026)

## Overview

938 specs, 0 failures, 95% line coverage, 82% branch coverage.
RSpec with FactoryBot, Faker, shoulda-matchers, database_cleaner.
No system specs — all testing via request specs and model specs.

---

## Coverage Gaps

### Policies Without Specs (9)

| Policy | Notes |
|--------|-------|
| `AdPolicy` | Inherits ApplicationPolicy defaults |
| `PlaylistPolicy` | Inherits defaults |
| `QrCodePolicy` | Inherits defaults |
| `ScreenPolicy` | **Has custom scope** — untested |
| `ScreenContentPolicy` | Inherits defaults |
| `ScreenPlayerPolicy` | Inherits defaults |
| `SitePolicy` | Inherits defaults |
| `ListingAgentPolicy` | Inherits defaults |
| `PlaylistAdPolicy` | Inherits defaults |

All inherit from `ApplicationPolicy` (which is tested). The
defaults cover read-all + write-managers+. However, `ScreenPolicy`
has a custom scope for cross-site joins that is never tested.

**Risk:** Low for most (defaults are correct). Medium for
`ScreenPolicy` (custom scope could silently break).

### Mailers Without Specs (3)

| Mailer | What it does |
|--------|-------------|
| `InquiryMailer` | Sends demo/contact form data to hello@replaytv.co |
| `InviteMailer` | Sends team invite with accept URL |
| `PasswordsMailer` | Sends password reset email |

**Risk:** Medium. Mailer specs verify subject, recipient, and
content. A typo in the recipient or broken URL would go
unnoticed.

### Models With Minimal Specs

| Model | What's tested | What's missing |
|-------|--------------|----------------|
| `Account` | Associations only | No validation specs, missing association coverage (screens, leads, qr_codes, experiences, invites) |
| `Session` | `belongs_to :user` only | No IP/user_agent storage tests |
| `QrCode` | Associations + scopes | `active` flag behavior, `ensure_qr_code!` method |

### Controllers Without Request Specs

| Controller | Notes |
|-----------|-------|
| `App::AccountsController` | Only new/create tested (signup). No edit/update (settings page) |
| `Go::ExperiencesController` | Public experience view — no spec |
| `Go::AgentsController` | Public agent view — no spec |

### Missing Factories

| Model | Notes |
|-------|-------|
| `Ahoy::Visit` | Created inline in rollup job spec |
| `Ahoy::Event` | Created inline in rollup job spec |

---

## Weak Specs

### Smoke Tests Only (No Content Assertions)

- **`spec/requests/admin/resources_spec.rb`** — every test only
  checks `be_successful`. Acceptable for admin but doesn't verify
  data appears on page.

- **`spec/requests/marketing/pages_spec.rb`** — 200 OK checks
  only. One headline assertion on home page.

### Superficial Model Specs

- **`spec/models/account_spec.rb`** — 3 association tests, no
  validations, no methods.

- **`spec/models/session_spec.rb`** — 1 association test. The
  Session model stores IP and user_agent on create — untested.

### Fragile Test Setup

- **`spec/controllers/authentication_spec.rb`** — tests
  `respond_to?(:current_user, true)` which is a smell. Should
  test actual behavior (e.g., calling current_user returns the
  signed-in user).

- **`spec/jobs/analytics_rollup_job_spec.rb`** — creates
  Ahoy::Visit and Ahoy::Event inline instead of factories.
  Fragile and inconsistent with test conventions.

---

## Missing Test Cases

### Auth Flow

| Missing | Risk |
|---------|------|
| Password reset with valid token (GET edit, PATCH update) | Medium — only invalid token tested |
| Session expiry/timeout behavior | Low |
| `ahoy.authenticate(user)` called on sign-in | Low — hard to test in request spec |

### Content Pipeline

| Missing | Risk |
|---------|------|
| Ad CRUD: agent role denied create/delete | Medium |
| PlaylistAd: test that positioning gem orders correctly | Low |
| Listing: `ensure_qr_code!` creates QR code on demand | Medium |
| Listing: associations (listing_agents, agents, ads, leads) | Low |

### Lead Capture

| Missing | Risk |
|---------|------|
| Lead DELETE action | Low (not in routes currently) |
| Go::LeadsController: lead linked to ahoy_visit via visitable | Medium |
| QR scan: test `qr.scanned` analytics event fires | Low (PORO specs cover validation) |

### Experience Flow

| Missing | Risk |
|---------|------|
| Experience PATCH with invalid params (422 path) | Low |
| Go::ExperiencesController: public kiosk view renders | Medium |
| Experience: kiosk template content assertions | Medium |

### Analytics

| Missing | Risk |
|---------|------|
| Integration test: event fires through Ahoy pipeline | Medium |
| Rollup job: verify per-account dimensions | Low |
| Ahoy Store: account_id enrichment from Current.account | Medium |
| Ahoy Store: account_id fallback from event properties | Medium |

### API

| Missing | Risk |
|---------|------|
| Heartbeat: test field updates (user_agent, ip_address, resolution) | Medium |
| Manifest: unpaired player returns appropriate response | Low |
| Manifest: attachment change produces different ETag | Medium |
| Player registration: test device fields populated from parse_user_agent! | Medium |

### Tenant Isolation

Coverage is strong — nearly every request spec includes a
"returns 404 for another account's resource" test. The
`authorization_spec.rb` covers agent/manager/owner boundaries
explicitly.

---

## Anti-patterns

### 1. Non-deterministic Factory Data

```ruby
# spec/factories/listings.rb
property_type { Listing::PROPERTY_TYPES.sample }
listing_type { Listing::LISTING_TYPES.sample }
```

A listing might be "sold" in one run and "active" in another.
Tests depending on status could intermittently fail.

**Fix:** Use fixed defaults (e.g., `"house"`, `"for_sale"`).
Use traits for variations.

### 2. Cross-Account Factory Associations

```ruby
# spec/factories/experiences.rb
factory :experience do
  account
  experienceable { association :listing_experience }
  # listing_experience creates its own listing with a DIFFERENT account
end
```

The listing may end up on a different account than the
experience. Tests pass because acts_as_tenant isn't enforced
in model specs, but this is incorrect data.

**Fix:** Pass account through transient attributes or use
`after(:build)` to align associations.

### 3. No System Specs

The app heavily uses Stimulus controllers (slideshow, experience,
device_pairing, device_playback, view_toggle, mobile_menu) and
Turbo. None of these are tested. Request specs can't test:
- JS-driven interactions (touch, swipe, idle mode)
- Turbo Frame/Stream behavior
- ActionCable real-time updates
- Form submissions via Turbo

**Impact:** High. Stimulus controllers contain critical business
logic (impression recording, kiosk sessions, manifest polling).

### 4. Manual Record Creation in Specs

Several specs create records inline instead of using factories:
- `analytics_rollup_job_spec.rb` (Ahoy records)
- `redirect_tracking_spec.rb` was removed (correct)
- `authentication_spec.rb` uses `ApplicationController.new`

---

## Critical Path Coverage Assessment

| Path | Rating | Key Gaps |
|------|--------|----------|
| Auth (login, session, logout) | **Good** | Missing valid password reset token test |
| Content pipeline (listing → ad → playlist → screen → player) | **Good** | Missing agent role auth on ads |
| Lead capture (QR scan → go page → lead) | **Strong** | Missing visitable link assertion |
| Experience flow (create → assign → kiosk render) | **Good** | Missing public kiosk render spec |
| Analytics (governed events) | **Partial** | No integration test through Ahoy |
| Tenant isolation | **Strong** | Well-covered across all request specs |
| Player content sync (manifest) | **Good** | Missing attachment change ETag test |
| Device enrichment | **Good** | Missing registration field population test |

---

## Summary Statistics

| Category | Has Spec | Missing Spec | Coverage |
|----------|----------|-------------|----------|
| Models (20) | 16 | 4 (minimal/none) | 80% |
| Request specs (30 controllers) | 26 | 4 | 87% |
| Policies (15) | 6 | 9 | 40% |
| Mailers (5) | 2 | 3 | 40% |
| Jobs (1) | 1 | 0 | 100% |
| Helpers (3) | 3 | 0 | 100% |
| Channels (2) | 0 | 2 | 0% |

**Highest risk gaps:** Mailer specs, ScreenPolicy custom scope,
Go controller specs, analytics integration, non-deterministic
factory data.
