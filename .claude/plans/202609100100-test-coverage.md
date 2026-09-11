# Plan: Test Coverage Improvement

## Context

Audit found 938 specs passing with 95% line / 82% branch
coverage. Core paths (auth, content pipeline, lead capture,
tenant isolation) are well covered. Gaps exist in policies,
mailers, public controllers, analytics integration, and factory
quality. See `.claude/analysis/test-suite-audit.md` for the
full audit.

## Goals

1. Fix anti-patterns (non-deterministic factories, cross-account
   associations)
2. Add missing specs for critical paths
3. Improve coverage on under-tested areas
4. Raise branch coverage above 85%

---

## Phase 1: Fix Anti-patterns

### 1.1 Fix non-deterministic factory data

```ruby
# spec/factories/listings.rb — BEFORE
property_type { Listing::PROPERTY_TYPES.sample }
listing_type { Listing::LISTING_TYPES.sample }

# AFTER
property_type { "house" }
listing_type { "for_sale" }

trait :condo do
  property_type { "condo" }
end

trait :for_rent do
  listing_type { "for_rent" }
end
```

### 1.2 Fix cross-account experience factory

Ensure listing_experience's listing shares the same account
as the experience.

### 1.3 Add Ahoy factories

```ruby
factory :ahoy_visit, class: "Ahoy::Visit" do
  visit_token { SecureRandom.hex(16) }
  visitor_token { SecureRandom.hex(16) }
  started_at { Time.current }
end

factory :ahoy_event, class: "Ahoy::Event" do
  ahoy_visit
  name { "test.event" }
  properties { {} }
  time { Time.current }
end
```

---

## Phase 2: Mailer Specs

### 2.1 InquiryMailer spec

- Test notification email: correct recipient (hello@replaytv.co),
  subject includes inquiry type and name, body includes all fields
- Test with demo_request and general inquiry types

### 2.2 InviteMailer spec

- Test invite email: correct recipient (invite.email), subject,
  body includes accept URL with token
- Test URL is for app subdomain

### 2.3 PasswordsMailer spec

- Test reset email: correct recipient, subject, body includes
  reset URL with token

---

## Phase 3: Policy Specs

### 3.1 ScreenPolicy spec

Priority — has a custom scope that's untested.

- Test scope filters screens by account via sites join
- Test default permissions (read-all, write-managers+)

### 3.2 Batch policy specs

For the 8 remaining policies that inherit defaults:
- One shared example group that tests the ApplicationPolicy
  defaults (index?/show? = true, create?/update?/destroy? =
  managers+)
- Include in each policy spec with one line

---

## Phase 4: Missing Controller Specs

### 4.1 Go::ExperiencesController spec

- Test public access (no auth required)
- Test renders experience kiosk view
- Test 404 for non-existent experience

### 4.2 Go::AgentsController spec

- Test public access
- Test renders agent profile
- Test 404

### 4.3 App::AccountsController edit/update spec

- Test edit renders settings form
- Test update changes account name
- Test owner-only access

---

## Phase 5: Missing Model Test Cases

### 5.1 Listing model

- Test `ensure_qr_code!` creates QR code
- Test missing associations (listing_agents, agents, ads, leads)
- Test photo/floor_plan attachments

### 5.2 Account model

- Test all associations (sites, screens, listings, agents, ads,
  playlists, experiences, leads, qr_codes, invites)

### 5.3 QrCode model

- Test `active` flag behavior
- Test `destination?` method

### 5.4 Screen model

- Test `active_screen_content` returns correct content
- Test `content_type` returns :playlist, :experience, or :none

---

## Phase 6: API Spec Gaps

### 6.1 Heartbeat spec

- Test updates `last_heartbeat_at`, `ip_address`, `user_agent`
- Test updates `screen_width`, `screen_height` from params
- Test re-parses user agent when changed

### 6.2 Player registration spec

- Test `parse_user_agent!` populates device fields
- Test accepts `app_version`, `screen_width`, `screen_height`,
  `touch_capable`

### 6.3 Manifest spec additions

- Test attachment change produces different ETag
- Test deploy version change produces different ETag
- Test experience with listing and agent in dependency tree

---

## Phase 7: Auth Flow Gaps

### 7.1 Password reset full flow

- Test GET /passwords/:token/edit with valid token
- Test PATCH /passwords/:token with valid token + new password
- Test expired token handling

### 7.2 Authentication concern

- Replace `respond_to?` test with actual behavior test
- Test `current_user` returns the signed-in user
- Test `current_account` returns the user's account

---

## Phase 8: Analytics Specs

### 8.1 Governed event integration

- Test that `Analytics::Events::QrScanned.create(request:)`
  calls `Ahoy::Tracker#track` with correct event name and
  properties

### 8.2 Ahoy Store spec

- Test `track_visit` sets `account_id` from `Current.account`
- Test `track_event` sets `account_id` from `Current.account`
- Test `track_event` falls back to `props[:account_id]`
- Test admin subdomain excluded

---

## Phase 9: Channel Specs (Optional)

### 9.1 ScreenChannel spec

- Test subscribes with valid player token
- Test rejects without valid token
- Test streams from correct screen channel

### 9.2 PairingChannel spec

- Test subscribes with valid pairing code
- Test receives paired event

---

## Build Order

### Priority 1 — Fix anti-patterns (immediate)
1. Fix listing factory (deterministic defaults)
2. Fix experience factory (same-account associations)
3. Add Ahoy factories

### Priority 2 — Critical path gaps
4. Mailer specs (3 mailers)
5. ScreenPolicy spec (custom scope)
6. Go::ExperiencesController spec
7. Password reset full flow
8. Heartbeat field update spec
9. Manifest attachment ETag spec

### Priority 3 — Coverage breadth
10. Batch policy specs (shared examples)
11. Account/Listing/QrCode model enrichment
12. Go::AgentsController spec
13. Player registration device fields spec
14. Authentication concern behavior test

### Priority 4 — Nice to have
15. Analytics integration specs
16. Ahoy Store spec
17. Channel specs
18. System specs (future — requires Capybara + headless Chrome)

---

## Expected Impact

| Metric | Current | After Priority 1-2 | After All |
|--------|---------|--------------------|-----------| 
| Specs | 938 | ~990 | ~1050 |
| Line coverage | 95% | 96% | 97%+ |
| Branch coverage | 82% | 85% | 87%+ |
| Policies with specs | 40% | 53% | 100% |
| Mailers with specs | 40% | 100% | 100% |
