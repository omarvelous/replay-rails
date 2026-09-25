# Plan: MVP Launch Readiness

**Created:** 2026-09-23
**Status:** Draft
**Branch:** TBD

## Context

Comprehensive audit scored the app 3.8/5. The core product loop
works end-to-end but several gaps block real customer usage.
This plan addresses everything needed before the first brokerage
signs up.

---

## Phase 1 — Critical (blocks any real usage)

### 1. Account name + settings page

**Problem:** Account has no `name` column. Accounts are
indistinguishable. No settings page exists.

**Fix:**
- Migration: add `name` string column to accounts (NOT NULL)
- Update account creation flow (signup form collects account name)
- Account settings page at `/settings` (edit name, view plan)
- Update seeds to name demo accounts
- Update admin dashboard to show account names
- Update CLAUDE.md

### 2. Enable SSL in production

**Problem:** `force_ssl` and `assume_ssl` commented out in
`config/environments/production.rb`. Cookies transmit in clear
text, no HSTS, no HTTP→HTTPS redirect.

**Fix:**
- Uncomment `config.assume_ssl = true`
- Uncomment `config.force_ssl = true`
- Verify Render handles SSL termination (it does)

### 3. Configure CSP headers

**Problem:** Entire `content_security_policy.rb` initializer is
commented out. No XSS browser-level mitigation.

**Fix:**
- Configure CSP allowing:
  - self for scripts, styles, images, fonts
  - CDN hosts for TailwindPlus Elements, Swagger UI
  - ActionCable WebSocket connections
  - Ahoy tracking
  - Inline scripts for player JS (nonce-based)
- Test each subdomain — marketing, app, play, admin may need
  different policies

### 4. Configure SMTP for production

**Problem:** SMTP settings commented out in production.rb. No
emails send in production.

**Fix:**
- Configure SMTP via environment variables (Postmark, SendGrid,
  or Amazon SES)
- Set `config.action_mailer.smtp_settings` from credentials
- Set `default_url_options` for production email links
- Test: lead notification, invite, password reset

### 5. User profile edit page

**Problem:** Users can't change their own name, email, or
password from within the app.

**Fix:**
- Add `edit` and `update` to `App::UsersController` (self only)
- Profile edit view with name, email, password change
- Policy: users can edit themselves, managers+ can view others
- Navigation link to profile

### 6. Remove COMING_SOON gate

**Problem:** `COMING_SOON=true` in production env vars. Entire
app is behind a static page.

**Fix:**
- Remove `COMING_SOON` from Render env vars when ready to launch
- Consider converting to a feature flag per account instead of
  global middleware

---

## Phase 2 — Important (should fix before launch)

### 7. Ads index N+1

**Problem:** `AdsController#index` doesn't include adable or
image_attachment. Every ad card triggers separate queries.

**Fix:**
- Add `.includes(:adable, :image_attachment)` to the index query
- Verify with Bullet in development

### 8. Schedule cleanup jobs

**Problem:** `PlayerCleanupJob` and `VersionCleanupJob` exist
but are never scheduled in `config/recurring.yml`.

**Fix:**
- Add to recurring.yml:
  ```yaml
  player_cleanup:
    class: PlayerCleanupJob
    schedule: every day at 3am
  version_cleanup:
    class: VersionCleanupJob
    schedule: every day at 4am
  ```

### 9. Host header validation

**Problem:** `config.hosts` commented out. DNS rebinding attacks
possible.

**Fix:**
- Configure `config.hosts` in production.rb with:
  `replaytv.co`, `*.replaytv.co`, `replaytv.dev`, `*.replaytv.dev`

### 10. Rack::Attack production store

**Problem:** Rate limits use MemoryStore — reset on restart, don't
work across Puma workers.

**Fix:**
- Switch to `Rails.cache` (Solid Cache in production):
  ```ruby
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new
  # or use Solid Cache adapter
  ```

### 11. Session cookie expiration

**Problem:** `cookies.signed.permanent[:session_id]` — sessions
never expire from the cookie side.

**Fix:**
- Change `permanent` to explicit `expires: 30.days.from_now`
- Users re-login monthly

### 12. Dashboard query caching

**Problem:** DashboardPresenter runs 7+ queries on every page load
including Ahoy event counts.

**Fix:**
- Fragment cache dashboard stats with 5-minute TTL
- Or memoize in presenter with `Rails.cache.fetch`

---

## Phase 3 — Business blockers (Tier 2, needed for revenue)

### 13. Subscriptions / Billing

The #1 business blocker. Can't charge without it.

**Approach:** Stripe Billing with tiered plans (Starter, Professional,
Enterprise). `Subscription` model on Account. Feature gating via
`account.plan.feature_enabled?`. Screen count enforcement.

**Separate plan needed** — this is a full feature, not a fix.

### 14. Notification system

Only new-lead email exists. Need:
- Player offline alerts (email after 15 min)
- QR milestone notifications
- In-app notification bell
- User notification preferences

**Separate plan needed.**

### 15. Content scheduling / Day-parting

Brokerages want open house ads on weekends only. Time-of-day and
day-of-week scheduling on playlists.

**Plan exists:** `.claude/plans/drafts/plan-day-parting-scheduling.md`

---

## Execution Order

### Week 1 — Critical security + infrastructure
- SSL enforcement (#2)
- CSP headers (#3)
- SMTP configuration (#4)
- Host validation (#9)
- Rack::Attack store (#10)
- Session expiration (#11)

### Week 2 — Account + user experience
- Account name column + settings page (#1)
- User profile edit (#5)
- Ads N+1 fix (#7)
- Schedule cleanup jobs (#8)
- Dashboard caching (#12)

### Week 3 — Launch prep
- Remove COMING_SOON gate (#6)
- End-to-end smoke test as a new user
- Demo walkthrough with real data

### Post-launch
- Subscriptions (#13)
- Notifications (#14)
- Content scheduling (#15)

---

## Out of Scope

- Offline player resilience (Tier 3)
- StreetEasy listing import (draft plan exists)
- SMS/NFC lead capture (draft plans exist)
- Contextual QR codes (draft plan exists)
- Native app client credentials
- i18n, white-labeling, GDPR (Tier 4)
