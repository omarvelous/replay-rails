# Product Roadmap

## Where we are

The core product loop is built: listings → ads → playlists → screens →
QR scans → leads → agent inbox. Admin panel (Administrate), subdomain
architecture (marketing, app, admin, play, api), and test infrastructure
are in place. 725 specs, 95% line coverage.

All Tier 1 launch blockers are shipped. The platform is functionally
ready for a private beta.

---

## Shipped

| Item | Branch/PR | What was built |
|------|-----------|----------------|
| RBAC | `rbac` | AccountUser join model with multi-role support (owner, manager, agent). Action Policy for authorization with policy classes per model. Authorizable concern on User. |
| User invites | `user-invites` | Token-based invite flow with 3 accept paths (auto-accept, login redirect, registration). Role assigned at invite time. InviteMailer. |
| Rate limiting | `rate-limiting` | Rack::Attack throttling on public endpoints (leads, scans, player registration). Honeypot on lead form. |
| Analytics | `analytics` | Impression model (8 FKs), MetricSnapshot with daily rollups, MetricsRollupJob, Chartkick dashboard with 30-day funnel chart. |
| Pagination | `pagination` | Pagy on all index pages with custom Tailwind pagination partial. |
| Audit trail | `audit-trail` | paper_trail on 16 models with jsonb columns, account_id on versions, whodunnit via Current.user. Admin dashboard activity feed + Administrate versions index. |
| API restructure | `play-to-api-refactor` | Split monolithic player API into `play` subdomain (HTML) and `api` subdomain (JSON). |
| Documentation | `documentation` #23 | In-app docs system (Docs::Manifest, Docs::PagesController), 12 developer docs, 10 user-facing doc pages, repo reorg. |
| Tenant scoping | `tenant-scoping` | `acts_as_tenant` on 11 models for automatic query scoping. Simplified policy scopes. Cross-tenant access via `without_tenant` for admin and jobs. |
| Code organization | `code-organization` | File structure standard for 7 file types. Audited and fixed all models, controllers, routes, policies, factories, Gemfile. Contributing guide. |

---

## Priority tiers

### Tier 1 — Before launch ✓ SHIPPED

All four launch blockers are complete.

### Tier 2 — At launch

Can ship without these but can't sustain a business.

| Item | Why it's needed at launch | Status |
|------|--------------------------|--------|
| Subscriptions | Can't charge without billing. Stripe Billing, plan tiers, feature gating. | Not started |
| Notifications | Leads email agents, but nothing else alerts users. Player offline, milestone scans, new team member. | Not started |
| Content scheduling | Brokerages want open house ads on weekends only. Day-parting and date ranges. | Plan exists |

### Tier 3 — Soon after launch

Quality-of-life for active accounts. Builds stickiness.

| Item | Why | Status |
|------|-----|--------|
| Documentation | In-app docs at `/docs` for office managers and agents. Dev docs in repo. | In progress |
| Media library | Shared photos/assets per account instead of per-model uploads. Reuse across ads. | Not started |
| Offline resilience | Player caches playlist locally. Keeps playing when internet drops. | Not started |

### Tier 4 — Market-driven

Priority depends on which markets you enter and what customers ask for.

| Item | Trigger |
|------|---------|
| i18n | Canadian market (bilingual requirement) or international expansion. |
| White-labeling | Enterprise brokerages want their brand, not yours. Custom themes per account, custom domains. |
| GDPR / data retention | European market or enterprise compliance requirements. PII in leads + IP in scans. |
| CRM integration | "Push leads to Salesforce" — enterprise ask, not SMB. |

---

## Tier 2 — Detailed breakdown

### 1. Subscriptions / Monetization

**Key decision first:** What's the billing unit?

| Model | Pros | Cons |
|-------|------|------|
| Per-screen | Scales with usage. Easy to understand. | Small accounts feel nickel-and-dimed. |
| Per-site | Simpler. Encourages more screens per office. | Doesn't scale with large offices. |
| Flat per-account with tiers | Predictable for customers. | Requires defining tier limits. |

**Suggested:** Tiered per-account with screen limits.

| Plan | Screens | Price | Features |
|------|---------|-------|----------|
| Starter | 1 | $49/mo | Core features, 1 user |
| Professional | 5 | $149/mo | Lead capture, analytics, 5 users |
| Enterprise | Unlimited | Custom | White-label, SSO, API, dedicated support |

**Tech:**
- Stripe Billing for subscriptions
- `Subscription` model on Account (plan, stripe_subscription_id, status, current_period_end)
- `Account#plan` for feature checks: `Current.account.plan.leads_enabled?`
- Webhook endpoint for Stripe events (invoice.paid, subscription.updated, etc.)
- Screen count enforcement in `ScreensController#create`

---

### 2. Notifications

**Current state:** `LeadMailer#new_lead` is the only notification.
Ad-hoc, not extensible.

**Target state:** Unified notification system with multiple channels.

**Events worth notifying:**
- New lead submitted (email — already exists)
- Player went offline (email after 15 min)
- Player came back online (in-app only)
- QR code milestone (100 scans, 500 scans — email)
- User joined the account (in-app)
- Lead status changed to qualified (email to owner)

**Approach:** `Notification` model (account, user, event, read_at)
with an in-app notification bell + optional email delivery per event
type. User preferences for which events send email.

---

### 3. Content scheduling / Day-parting

**Current state:** Playlists play 24/7. No time-based control.

**Target state:** Schedule playlists by time-of-day and day-of-week.
"Open house ads only Saturday/Sunday 10am-4pm."

**Plan exists:** `.claude/plans/` — review and update before executing.

---

## Tier 3 — Brief notes

### 4. Documentation

In-app user docs at `/docs` under a standalone `Docs` module. Dev docs
in `docs/dev/` in the repo. Pure ERB with Tailwind prose styling.
**Plan:** `.claude/plans/202608281530-documentation.md`

### 5. Media library

`MediaAsset` model per account. Shared pool of uploaded images.
Ads, listings, agents reference media assets instead of direct
ActiveStorage attachments. Enables reuse, tagging, bulk upload.

### 6. Offline resilience

Player-side concern. The play endpoint returns a manifest of ads
with image URLs. Player caches this locally (Service Worker or
native cache). On heartbeat failure, keeps playing the cached
playlist. Reconnects automatically.

---

## Tier 4 — Brief notes

### 7. i18n

Extract all user-facing strings to locale YAML files. Use
`t(".heading")` in views. Start with `en` + `fr` (Canada).
The longer this waits, the more strings to extract.

### 8. White-labeling

Per-account theme overrides (logo, primary color, accent color).
Custom domain for `/go/` landing pages (CNAME + Let's Encrypt).
Enterprise tier feature.

### 9. GDPR / Data retention

- Consent checkbox on lead form
- Data retention policy (delete leads older than N months)
- Right to deletion endpoint (delete all PII for an email)
- IP anonymization on scan records after 30 days

### 10. CRM integration

Webhook on lead creation → push to Salesforce, HubSpot, or
Follow Up Boss (popular in real estate). Start with a generic
webhook URL per account, then build native integrations based
on customer demand.

---

## Execution order

```
Tier 1 ─── SHIPPED ──────────────────────────┐
                                              │
Subscriptions ─┤                              │
Notifications ─┤── Tier 2 (at launch) ───────┤
Scheduling ────┘                              │
               │                              │
Documentation ─┤                              ├── Revenue
Media Library ─┤── Tier 3 (stickiness) ──────┘
Offline ───────┘
               │
i18n ──────────┤
White-label ───┤── Tier 4 (market-driven)
GDPR ──────────┤
CRM ───────────┘
```

Subscriptions is the next critical path item — can't sustain the
business without billing. Notifications and scheduling are parallel.
Documentation is in progress.

---

## Existing plans

| Plan | Location | Status |
|------|----------|--------|
| Documentation | `.claude/plans/202608281530-documentation.md` | In progress |
| Day-parting / Scheduling | `.claude/plans/drafts/plan-day-parting-scheduling.md` | Draft — needs review |
| Live Preview | `.claude/plans/drafts/plan-live-preview.md` | Draft — needs review |
