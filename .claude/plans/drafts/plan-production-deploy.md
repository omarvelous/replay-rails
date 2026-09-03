# Plan: Production Deploy (Draft)

## Problem

Staging is live but production has not been deployed. Several pieces
need to come together before `replaytv.co` is live:

- Production Render services created and deployed
- Production Cloudflare DNS provisioned via OpenTofu (replaytv.co + subdomains)
- Custom domains added in Render, SSL verified
- `rply.tv` short domain configured for QR scan URLs
- Production database migrated and seeded
- Production R2 bucket for ActiveStorage
- Production credentials/secrets set

## Items

### DNS + Domains

- **OpenTofu production apply** — run `tofu apply` for the production
  environment to create DNS records for `replaytv.co`, `*.replaytv.co`,
  and `rply.tv` pointing to the production Render CNAME
- **Render custom domains** — add all 6 domains to the production web
  service: `replaytv.co`, `app.replaytv.co`, `admin.replaytv.co`,
  `play.replaytv.co`, `api.replaytv.co`, `rply.tv`
- **Verify SSL** — confirm Let's Encrypt certs issued for all domains
- **Test all subdomains** — verify routing works for each

### Short domain (rply.tv)

- **DNS** — `rply.tv` CNAME pointing to production Render service
  (handled by OpenTofu production config)
- **Render** — add `rply.tv` as custom domain on production web service
- **Rails routing** — the `/s/:token` scan route is already defined
  outside subdomain constraints, so it works on any domain including
  `rply.tv`
- **QR helper** — update `qr_svg` to use a configurable base URL for
  QR codes. Production uses `https://rply.tv/s/:token`, staging uses
  the full staging domain. Config via environment variable or Rails
  credentials:
  ```ruby
  ENV.fetch("QR_BASE_URL", request.base_url) + "/s/#{qr_code.token}"
  ```
- **Test** — verify `rply.tv/s/:token` redirects correctly and QR
  codes generated in ads are scannable and resolve

### Database + Storage

- **Run migrations** — `bin/rails db:prepare` on production
- **Solid schemas** — load queue/cache/cable schemas:
  ```bash
  bin/rails db:schema:load:queue
  bin/rails db:schema:load:cache
  bin/rails db:schema:load:cable
  ```
- **R2 bucket** — verify `replay-production` bucket exists (created
  by OpenTofu) and R2 credentials are set
- **Seed** — decide whether to seed demo data or start clean

### Secrets + Config

- **RAILS_MASTER_KEY** — set in production Render env var group
- **R2 credentials** — set in production (or migrate to Rails
  credentials per the credentials plan)
- **Production environment** — verify `config/environments/production.rb`
  doesn't need a `tld_length` or `default_url_options` override
  (production uses `replaytv.co` with standard TLD length of 1)

### Verification

- **Health check** — `replaytv.co/up` returns 200
- **Marketing site** — `replaytv.co` loads
- **App login** — `app.replaytv.co/session/new` works
- **Player pairing** — `play.replaytv.co` → pair → content plays
- **QR scan** — `rply.tv/s/:token` redirects to landing page
- **Admin** — `admin.replaytv.co` loads
- **API** — `api.replaytv.co/players` responds
- **Image uploads** — photos upload to R2 and display correctly
