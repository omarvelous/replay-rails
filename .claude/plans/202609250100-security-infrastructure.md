# Plan: Security & Infrastructure Hardening (Week 1)

**Created:** 2026-09-24
**Status:** Draft
**Branch:** `security-hardening`

## Overview

6 items from the MVP audit that harden the app for production.
All are configuration/infrastructure — no feature code, minimal
specs needed.

---

## 1. Enable SSL in production

### Problem
`force_ssl` and `assume_ssl` commented out in production.rb.
Cookies transmit in clear text, no HSTS, no HTTP→HTTPS redirect.

### Fix
```ruby
# config/environments/production.rb
config.assume_ssl = true     # Render terminates SSL, forwards HTTP
config.force_ssl = true      # HSTS header + redirect HTTP → HTTPS
```

Two lines. Render handles SSL termination, so `assume_ssl` tells
Rails the connection is secure even though Render forwards as HTTP
internally. `force_ssl` adds HSTS and redirects any direct HTTP
requests.

### Verification
- Deploy to staging, confirm HTTPS redirect works
- Confirm cookies have `Secure` flag in browser devtools

---

## 2. Configure CSP headers

### Problem
Entire `content_security_policy.rb` initializer commented out.
No browser-level XSS mitigation.

### External resources audit

| Domain | Type | Used by |
|--------|------|---------|
| `cdn.jsdelivr.net` | script | TailwindPlus Elements (app layout) |
| `unpkg.com` | script + style | Swagger UI (docs page only) |
| `*.r2.cloudflarestorage.com` | img | Active Storage redirects in production |

### Inline resources

| Type | Count | Approach |
|------|-------|---------|
| Importmap scripts | Every page (6 layouts) | Nonce-based (Rails `nonce_auto`) |
| Chartkick scripts | Dashboard, admin | Verify nonce compatibility |
| Player unpaired redirect | 1 inline script | Add nonce |
| Swagger UI init | 1 standalone page | Exempt or add nonce |
| Inline `style=` attributes | ~425 across views | `unsafe-inline` on style-src |

### Implementation

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self
    policy.img_src     :self, :data, "https://*.r2.cloudflarestorage.com"
    policy.object_src  :none
    policy.script_src  :self,
                       "https://cdn.jsdelivr.net",
                       "https://unpkg.com"
    policy.style_src   :self,
                       "https://unpkg.com",
                       :unsafe_inline
    policy.connect_src :self
    policy.form_action :self
    policy.frame_ancestors :none
  end

  # Nonce-based script loading for importmap + inline scripts
  config.content_security_policy_nonce_generator = ->(request) {
    request.session.id.to_s
  }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Start in report-only mode, switch to enforcement after testing
  config.content_security_policy_report_only = true
end
```

### Nonce handling

Rails 8 with `nonce_directives = ["script-src"]` auto-injects
nonces into `javascript_importmap_tags` and `javascript_tag`.

For ActionCable WebSocket, `connect-src` needs `self` which
covers `wss://` on the same origin. No explicit `wss://` needed
since each subdomain's WebSocket is same-origin.

### Rollout strategy

1. Deploy with `report_only: true`
2. Monitor Rails logs for CSP violations
3. Fix any blocked resources
4. Switch to enforcement: `report_only: false`
5. Verify each subdomain: marketing, app, play, admin, docs

### Action items
- Add `csp_meta_tag` to `player.html.erb` layout (missing)
- Handle Swagger UI standalone page (either exempt or nonce)
- Verify Chartkick works with nonces
- Determine R2 custom domain (or use `*.r2.cloudflarestorage.com`)

---

## 3. Configure SMTP (Resend)

### Problem
SMTP settings commented out in production.rb. Emails don't send.

### Fix

Add `resend` gem or use SMTP relay:

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: "smtp.resend.com",
  port: 465,
  user_name: "resend",
  password: Rails.application.credentials.dig(:resend, :api_key),
  authentication: :plain,
  tls: true
}

config.action_mailer.default_url_options = {
  host: "app.replaytv.co",
  protocol: "https"
}
```

Alternatively, use the `resend` Ruby SDK gem for API-based
delivery instead of SMTP:

```ruby
gem "resend"

# config/environments/production.rb
config.action_mailer.delivery_method = :resend
```

### Credentials
- Store Resend API key in Rails credentials:
  `rails credentials:edit --environment production`
- Add `resend.api_key`

### Verification
- Send a test lead from staging
- Verify invite email delivers
- Verify password reset email delivers

---

## 4. Host header validation

### Problem
`config.hosts` commented out. DNS rebinding attacks possible.

### Fix

```ruby
# config/environments/production.rb
config.hosts = [
  "replaytv.co",
  /.*\.replaytv\.co/,     # app, admin, play subdomains
  "replaytv.dev",
  /.*\.replaytv\.dev/,     # staging subdomains
  "rply.tv",               # QR short domain
  IPAddr.new("0.0.0.0/0") # health checks from load balancer
]
```

The last entry allows health check requests from Render's load
balancer which may use IP addresses.

---

## 5. Rack::Attack production store

### Problem
Rate limits use MemoryStore — reset on restart, don't share
across Puma workers.

### Fix

Solid Cache supports `increment`. Use `Rails.cache` directly:

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.cache.store = Rails.cache
```

One line. No Redis needed. Solid Cache is DB-backed, persists
across restarts, shared across workers.

### Verification
- Hit a rate-limited endpoint 11+ times in 1 minute
- Confirm 429 response
- Restart server, confirm counter persists

---

## 6. Session cookie expiration

### Problem
`cookies.signed.permanent[:session_id]` — sessions never expire
from the cookie side. A stolen session cookie works forever.

### Fix

```ruby
# app/controllers/concerns/authentication.rb
def start_new_session_for(user)
  user.sessions.create!(...).tap do |session|
    Current.session = session
    cookies.signed[:session_id] = {
      value: session.id,
      httponly: true,
      same_site: :lax,
      domain: :all,
      expires: 30.days.from_now  # was: permanent
    }
    ...
  end
end
```

Users re-login after 30 days of inactivity. Active users get a
fresh cookie on each login.

---

## Execution — COMPLETED

### Step 1 — SSL + hosts + session expiry ✓
- `assume_ssl` + `force_ssl` enabled in production
- Health check excluded from SSL redirect
- Host validation: replaytv.co + subdomains + rply.tv (production),
  replaytv.dev + subdomains (staging, separate config)
- Session cookie 30-day expiry (was permanent)

### Step 2 — Rack::Attack store ✓
- Rails.cache (Solid Cache) in production/staging
- MemoryStore in dev/test
- Fixed player registration throttle path: /api/v1/players

### Step 3 — CSP (report-only) ✓
- Nonce-based script loading, external CDN allowlisted
- unsafe-inline for styles (425 inline style attributes)
- frame-ancestors: none
- Added csp_meta_tag to player layout
- Deployed in report-only mode

### Step 4 — Resend email delivery ✓
- `resend` gem with `delivery_method = :resend`
- API key in Rails credentials
- DNS records (DKIM, SPF, DMARC) managed via OpenTofu

### Step 5 — OpenTofu infrastructure improvements ✓
- Resend DNS records (DKIM, SPF, DMARC) added to Cloudflare module
- DKIM key parameterized per environment
- terraform.tfvars for provider credentials (separate from .env)
- Wrapper script requires explicit TOFU_ENV (no production default)

### Remaining — CSP enforcement
- After monitoring report-only for a period, switch to enforcement:
  `config.content_security_policy_report_only = false`
- Verify all subdomains work (marketing, app, play, admin, docs)
