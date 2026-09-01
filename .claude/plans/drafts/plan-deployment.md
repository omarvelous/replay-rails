# Plan: Deployment Infrastructure (Draft)

## Goal

Deploy RePlay to a staging environment with wildcard subdomain support,
GitHub CI/CD, and SSL — enabling device testing against a real URL.
Then extend to production.

## Stack

| Component | Tool | Notes |
|-----------|------|-------|
| Deployment | Kamal 2 | Ships with Rails 8, Docker + SSH + Traefik |
| Hosting | Hetzner Cloud | CX22 staging, CX32 production |
| DNS | Cloudflare (free) | Wildcard A records, DNS-01 challenge for SSL |
| SSL | Let's Encrypt wildcard | Via Traefik + Cloudflare DNS API |
| Registry | GitHub Container Registry (GHCR) | Free for public/private repos |
| Database | PostgreSQL 17 | Kamal accessory (staging), managed (production) |
| File Storage | Cloudflare R2 | S3-compatible, no egress fees |
| CI/CD | GitHub Actions | Test → deploy on merge to main |
| Monitoring | Kamal health checks + uptime ping | Expand later |

---

## Prerequisites (before Phase 1)

- [ ] Hetzner Cloud account created
- [ ] Domain registered (or subdomain delegated) for staging
- [ ] Cloudflare account with domain added
- [ ] SSH key pair generated for deployment
- [ ] Cloudflare API token created (Zone:DNS:Edit scope)

---

## Build order

### Phase 1 — Staging server setup

1. Provision Hetzner CX22 (2 vCPU, 4 GB RAM, ~$5/mo)
   - Ubuntu 24.04
   - Add SSH public key during provisioning
   - Note the server IP
2. Cloudflare DNS: add wildcard A record `*.staging.replay.com → server IP`
3. Cloudflare DNS: add root A record `staging.replay.com → server IP`
4. Verify DNS resolves: `dig app.staging.replay.com`

### Phase 2 — Kamal configuration

5. Create `config/deploy.yml` for production (base config)
6. Create `config/deploy.staging.yml` with staging overrides:
   - Server IP
   - `*.staging.replay.com` domain
   - PostgreSQL as Kamal accessory
   - Staging-specific env vars
7. Configure Traefik for wildcard SSL via Cloudflare DNS-01:
   - `certificatesResolvers.letsencrypt.acme.dnsChallenge.provider: cloudflare`
   - `CF_DNS_API_TOKEN` as secret env
8. Configure GHCR as container registry
9. Set up Rails credentials for staging:
   - `RAILS_MASTER_KEY`
   - `DATABASE_URL`
   - `SECRET_KEY_BASE`
10. Commit Kamal config

### Phase 3 — First deploy

11. Run `kamal setup -d staging` — provisions Docker, Traefik, PostgreSQL, deploys app
12. Verify health check passes (`/up` endpoint)
13. Run migrations: `kamal app exec -d staging "bin/rails db:migrate"`
14. Seed staging data: `kamal app exec -d staging "bin/rails db:seed"`
15. Verify all subdomains work:
    - `https://staging.replay.com` — marketing
    - `https://app.staging.replay.com` — app (login)
    - `https://admin.staging.replay.com` — admin panel
    - `https://play.staging.replay.com/players/new` — player pairing
    - `https://api.staging.replay.com/players` — API
16. Verify SSL wildcard cert is valid for all subdomains
17. Verify WebSocket connection (ActionCable) on the play subdomain

### Phase 4 — GitHub Actions CI/CD

18. Create `.github/workflows/ci.yml` — test suite on all PRs:
    - PostgreSQL service container
    - `bundle exec rspec`
    - `bundle exec rubocop`
19. Create `.github/workflows/deploy-staging.yml` — deploy on push to `staging` branch:
    - SSH agent setup
    - Docker login to GHCR
    - `kamal deploy -d staging`
20. Store secrets in GitHub repo settings:
    - `SSH_PRIVATE_KEY`
    - `RAILS_MASTER_KEY`
    - `CF_DNS_API_TOKEN`
21. Test: push to `staging` branch, verify auto-deploy

### Phase 5 — ActiveStorage + file uploads

22. Create Cloudflare R2 bucket for staging
23. Configure `config/storage.yml` with S3-compatible R2 settings
24. Set `STORAGE_*` env vars in Kamal config
25. Set `config.active_storage.service = :cloudflare` in staging/production
26. Verify image uploads work (listing photos, agent photos, ad images)

### Phase 6 — Device testing

27. Point a Fire TV Stick at `https://play.staging.replay.com/players/new`
28. Verify full flow: pairing code → pair in app → content plays
29. Test with Raspberry Pi
30. Test with Amazon Signage Stick
31. Run 24/7 stress test for 1 week

### Phase 7 — Production environment

32. Provision Hetzner CX32 (4 vCPU, 8 GB RAM, ~$14/mo) for production
33. Decide on PostgreSQL: Kamal accessory vs Hetzner managed DB vs Neon/Supabase
34. Cloudflare DNS: `*.replay.com → production IP`
35. Create `config/deploy.yml` with production config
36. Create `.github/workflows/deploy-production.yml` — deploy on push to `main`
37. Run `kamal setup` for production
38. Verify all subdomains, SSL, WebSockets
39. Set up R2 bucket for production uploads

### Phase 8 — Operational hardening

40. Database backups:
    - Staging: daily `pg_dump` cron inside the postgres container, stored to R2
    - Production: managed DB handles this, or cron + R2
41. Uptime monitoring: free tier of BetterUptime, Upptime, or similar
    - Monitor `/up` on each subdomain
    - Alert on downtime (email or Slack)
42. Log access: `kamal app logs -d staging` for ad-hoc, consider Logflare/Papertrail for persistent
43. Rollback procedure: document `kamal rollback -d staging` and verify it works
44. SSL cert renewal: automatic via Traefik/Let's Encrypt (verify it renews before 90-day expiry)

---

## Rails changes needed

### Production/staging environment config

```ruby
# config/environments/staging.rb (new file, inherits from production)
require_relative "production"

Rails.application.configure do
  config.action_mailer.default_url_options = { host: "app.staging.replay.com" }
  # Any staging-specific overrides
end
```

### Dockerfile review

The existing Dockerfile (Rails 8 default) should work with Kamal.
Verify:
- Multi-stage build (builder + runtime)
- `EXPOSE 3000`
- `CMD ["./bin/rails", "server"]`
- Asset precompilation in build stage

### Storage config

```yaml
# config/storage.yml
cloudflare:
  service: S3
  endpoint: https://<account_id>.r2.cloudflarestorage.com
  access_key_id: <%= ENV["R2_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["R2_SECRET_ACCESS_KEY"] %>
  bucket: replay-staging
  region: auto
```

### CORS

If the play subdomain loads images from R2, configure CORS on the R2 bucket to allow `*.replay.com` and `*.staging.replay.com`.

---

## Cost summary

| Item | Staging | Production | Monthly |
|------|---------|------------|---------|
| Hetzner CX22 | $5/mo | — | $5 |
| Hetzner CX32 | — | $14/mo | $14 |
| PostgreSQL | Accessory ($0) | Managed (~$15-25) | $15-25 |
| Cloudflare (DNS + R2) | Free + ~$1 | Free + ~$3 | $4 |
| GHCR | Free | Free | $0 |
| GitHub Actions | Free (2000 min/mo) | Free | $0 |
| Domain | — | — | ~$12/yr |
| **Total** | | | **~$38-48/mo** |

---

## What's deferred

- **PR preview environments** — Kamal doesn't support natively. Script per-branch deploys to staging later, or evaluate Fly.io for previews only
- **Multi-region** — single server per environment until traffic warrants
- **CDN for assets** — Cloudflare's free proxy gives edge caching out of the box
- **Auto-scaling** — not needed at early stage
- **Database replication / read replicas** — single instance is fine
- **Terraform / infrastructure-as-code** — Kamal + manual Hetzner provisioning is sufficient for 2 servers
- **Error tracking** — Sentry or Honeybadger, add when in production with real users
