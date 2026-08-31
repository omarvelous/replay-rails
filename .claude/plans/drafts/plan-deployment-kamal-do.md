# Plan: Deployment with Kamal + DigitalOcean (Draft)

## Stack

| Component | Tool | Cost |
|-----------|------|------|
| Deployment | Kamal 2 (Rails 8 built-in) | Free |
| Hosting | DigitalOcean Droplets | $12-48/mo |
| Database | DO Managed PostgreSQL | $15/mo |
| DNS | Cloudflare (free) | Free |
| SSL | Let's Encrypt wildcard via Cloudflare DNS-01 | Free |
| Registry | GitHub Container Registry (GHCR) | Free |
| File Storage | DO Spaces (S3-compatible) | $5/mo |
| CI/CD | GitHub Actions | Free (2000 min/mo) |

---

## Prerequisites

- [ ] DigitalOcean account (use referral credits if available)
- [ ] Cloudflare account with `replay.com` (or staging domain) added
- [ ] Cloudflare API token created (Zone:DNS:Edit permission)
- [ ] SSH key pair for deployment (`ssh-keygen -t ed25519 -f ~/.ssh/kamal_deploy`)
- [ ] GitHub repo has container registry enabled (GHCR)

---

## Phase 1 — DigitalOcean infrastructure

### Staging droplet

1. Create a Droplet:
   - **Image**: Ubuntu 24.04
   - **Size**: Basic, Regular, $12/mo (2 GB RAM, 1 vCPU) — or $24/mo (4 GB, 2 vCPU) if budget allows
   - **Region**: NYC1 or SFO3 (closest to your users)
   - **Authentication**: Add your SSH key
   - **Hostname**: `replay-staging`
2. Note the Droplet IP address

### Managed PostgreSQL (staging)

3. Create a Managed Database:
   - **Engine**: PostgreSQL 17
   - **Size**: Basic, $15/mo (1 GB RAM, 1 vCPU, 10 GB storage)
   - **Region**: Same as droplet
   - **Database name**: `replay_staging`
4. Add the Droplet to the database's trusted sources
5. Note the connection string (DATABASE_URL)

### DO Spaces (file storage)

6. Create a Space:
   - **Name**: `replay-staging`
   - **Region**: Same as droplet
   - **CDN**: Enable (free with Spaces)
7. Create Spaces access keys (Access Key + Secret Key)
8. Set CORS: allow `*.staging.replay.com` origins

### Production (Phase 5 — do later)

Same pattern with larger droplet ($48/mo — 4 GB, 2 vCPU) and separate managed DB.

---

## Phase 2 — Cloudflare DNS

9. Add domain to Cloudflare (free plan)
10. Add DNS records:

**Staging:**
```
A    staging.replay.com       → <staging-droplet-ip>
A    *.staging.replay.com     → <staging-droplet-ip>
```

**Production (later):**
```
A    replay.com               → <prod-droplet-ip>
A    *.replay.com             → <prod-droplet-ip>
```

11. Set Cloudflare proxy status:
    - Root domain: **Proxied** (orange cloud) — gets CDN + DDoS protection
    - Wildcard: **DNS only** (gray cloud) — Cloudflare free tier doesn't proxy wildcard subdomains. Traefik handles SSL directly via Let's Encrypt
12. Create a Cloudflare API token:
    - Permissions: Zone → DNS → Edit
    - Zone Resources: Include → your domain
    - Save the token for Kamal config

---

## Phase 3 — Kamal configuration

### 13. Base deploy config

```yaml
# config/deploy.yml
service: replay-rails
image: ghcr.io/omarvelous/replay-rails

servers:
  web:
    hosts:
      - <prod-droplet-ip>
    labels:
      traefik.http.routers.replay-web.rule: "HostRegexp(`{subdomain:[a-z0-9-]+}.replay.com`) || Host(`replay.com`)"
      traefik.http.routers.replay-web.tls: "true"
      traefik.http.routers.replay-web.tls.certresolver: letsencrypt
      traefik.http.routers.replay-web.tls.domains[0].main: replay.com
      traefik.http.routers.replay-web.tls.domains[0].sans: "*.replay.com"
  worker:
    hosts:
      - <prod-droplet-ip>
    cmd: bundle exec rake solid_queue:start

proxy:
  app_port: 3000

registry:
  server: ghcr.io
  username: omarvelous
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - CF_DNS_API_TOKEN
    - SPACES_ACCESS_KEY_ID
    - SPACES_SECRET_ACCESS_KEY
  clear:
    RAILS_ENV: production
    RAILS_LOG_TO_STDOUT: "true"
    SOLID_QUEUE_IN_PUMA: "false"

traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt:/letsencrypt"
  args:
    entryPoints.websecure.address: ":443"
    entryPoints.web.address: ":80"
    entryPoints.web.http.redirections.entryPoint.to: websecure
    entryPoints.web.http.redirections.entryPoint.scheme: https
    certificatesResolvers.letsencrypt.acme.email: ops@replay.com
    certificatesResolvers.letsencrypt.acme.storage: /letsencrypt/acme.json
    certificatesResolvers.letsencrypt.acme.dnsChallenge: "true"
    certificatesResolvers.letsencrypt.acme.dnsChallenge.provider: cloudflare
    certificatesResolvers.letsencrypt.acme.dnsChallenge.resolvers: "1.1.1.1:53,8.8.8.8:53"
  env:
    secret:
      - CF_DNS_API_TOKEN

healthcheck:
  path: /up
  port: 3000
  max_attempts: 7
  interval: 20s

volumes:
  - "/data/storage:/rails/storage"
```

### 14. Staging destination override

```yaml
# config/deploy.staging.yml
servers:
  web:
    hosts:
      - <staging-droplet-ip>
    labels:
      traefik.http.routers.replay-web.rule: "HostRegexp(`{subdomain:[a-z0-9-]+}.staging.replay.com`) || Host(`staging.replay.com`)"
      traefik.http.routers.replay-web.tls.domains[0].main: staging.replay.com
      traefik.http.routers.replay-web.tls.domains[0].sans: "*.staging.replay.com"
  worker:
    hosts:
      - <staging-droplet-ip>

env:
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - CF_DNS_API_TOKEN
    - SPACES_ACCESS_KEY_ID
    - SPACES_SECRET_ACCESS_KEY
  clear:
    RAILS_ENV: staging
    RAILS_LOG_TO_STDOUT: "true"
    SOLID_QUEUE_IN_PUMA: "false"
```

### 15. Storage config

```yaml
# config/storage.yml
digitalocean:
  service: S3
  endpoint: https://nyc3.digitaloceanspaces.com
  access_key_id: <%= ENV["SPACES_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["SPACES_SECRET_ACCESS_KEY"] %>
  bucket: <%= ENV.fetch("SPACES_BUCKET", "replay-staging") %>
  region: nyc3
```

### 16. Staging environment file

```ruby
# config/environments/staging.rb
require_relative "production"

Rails.application.configure do
  config.action_mailer.default_url_options = {
    host: "app.staging.replay.com",
    protocol: "https"
  }
end
```

### 17. Set Kamal secrets

```bash
# Create .kamal/secrets (git-ignored) or use kamal env push
kamal env push -d staging \
  RAILS_MASTER_KEY=<from credentials> \
  DATABASE_URL=<from DO managed PG> \
  CF_DNS_API_TOKEN=<from Cloudflare> \
  SPACES_ACCESS_KEY_ID=<from DO> \
  SPACES_SECRET_ACCESS_KEY=<from DO> \
  KAMAL_REGISTRY_PASSWORD=<GitHub PAT or GITHUB_TOKEN>
```

### 18. Commit Kamal config

---

## Phase 4 — First deploy

19. Run initial setup:
```bash
kamal setup -d staging
```

This will:
- SSH into the staging droplet
- Install Docker
- Start Traefik with wildcard SSL config
- Pull and start the app container
- Run health check

20. Run migrations:
```bash
kamal app exec -d staging "bin/rails db:migrate"
```

21. Seed staging data:
```bash
kamal app exec -d staging "bin/rails db:seed"
```

22. Verify all subdomains:

| URL | Expected |
|-----|----------|
| `https://staging.replay.com` | Marketing home |
| `https://app.staging.replay.com` | App login |
| `https://admin.staging.replay.com` | Admin panel |
| `https://play.staging.replay.com/players/new` | Player pairing |
| `https://api.staging.replay.com/players` | JSON API |

23. Verify SSL: check that each subdomain has a valid Let's Encrypt wildcard cert
24. Verify WebSockets: pair a player, confirm ActionCable pushes playlist changes
25. Verify uploads: create a listing with photos, confirm images load from DO Spaces

---

## Phase 5 — GitHub Actions CI/CD

### 26. CI workflow (all PRs)

```yaml
# .github/workflows/ci.yml
name: CI
on:
  pull_request:
    branches: [main, staging]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: replay_test
        ports: ["5432:5432"]
        options: >-
          --health-cmd="pg_isready"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
    env:
      DATABASE_URL: postgres://postgres:test@localhost:5432/replay_test
      RAILS_ENV: test
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bin/rails db:test:prepare
      - run: bundle exec rspec
      - run: bundle exec rubocop
```

### 27. Staging deploy workflow

```yaml
# .github/workflows/deploy-staging.yml
name: Deploy Staging
on:
  push:
    branches: [staging]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: kamal deploy -d staging
        env:
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
```

### 28. Production deploy workflow

```yaml
# .github/workflows/deploy-production.yml
name: Deploy Production
on:
  push:
    branches: [main]

jobs:
  test:
    # Same as CI job above
    ...

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: kamal deploy
        env:
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
```

### 29. GitHub secrets to configure

| Secret | Value |
|--------|-------|
| `SSH_PRIVATE_KEY` | Private key for the deploy SSH keypair |
| `RAILS_MASTER_KEY` | From `config/master.key` |
| `CF_DNS_API_TOKEN` | Cloudflare API token |

---

## Phase 6 — Device testing on staging

30. Configure Fire TV Stick with `https://play.staging.replay.com/players/new`
31. Pair via `https://app.staging.replay.com`
32. Verify full flow: pairing → content plays → playlist changes push → heartbeat
33. Repeat with Raspberry Pi and Signage Stick
34. Run all devices 24/7 for 1 week — monitor for WebSocket drops, memory leaks, recovery after power cycle

---

## Phase 7 — Production environment

35. Provision production Droplet: $24-48/mo (4 GB, 2 vCPU recommended)
36. Provision production Managed PostgreSQL: $15/mo
37. Provision production DO Space: `replay-production`
38. Cloudflare DNS: `replay.com` + `*.replay.com` → production IP
39. Update `config/deploy.yml` with production server IP
40. `kamal setup` for production
41. Migrate, seed initial data
42. Verify all subdomains, SSL, WebSockets, uploads

---

## Phase 8 — Operational hardening

43. **Database backups**: DO Managed PG includes daily automated backups (7-day retention on basic plan)
44. **Uptime monitoring**: BetterUptime or UptimeRobot (free tier) — ping `https://replay.com/up` every 5 minutes
45. **Deploy notifications**: GitHub Actions notifies on failure; add Slack webhook for deploy success/failure
46. **Rollback**: Document and test `kamal rollback -d staging` and `kamal rollback`
47. **SSL renewal**: Automatic via Traefik + Let's Encrypt (verify cert renews before 90-day expiry)
48. **Firewall**: DO Cloud Firewall — allow 80, 443, 22 (SSH) only
49. **Log access**: `kamal app logs -d staging -f` for streaming; add Papertrail or Logflare for persistent logs when needed

---

## Cost summary

### Staging only (Phase 1-4)

| Item | Monthly |
|------|---------|
| DO Droplet (2 GB) | $12 |
| DO Managed PostgreSQL | $15 |
| DO Spaces | $5 |
| Cloudflare | Free |
| GHCR + GitHub Actions | Free |
| **Total** | **$32/mo** |

### Staging + Production

| Item | Monthly |
|------|---------|
| Staging Droplet | $12 |
| Production Droplet | $24-48 |
| 2x Managed PostgreSQL | $30 |
| 2x DO Spaces | $10 |
| Cloudflare | Free |
| **Total** | **$76-100/mo** |

---

## Kamal cheat sheet

```bash
# Deploy
kamal deploy                    # production
kamal deploy -d staging         # staging

# Logs
kamal app logs                  # production logs
kamal app logs -d staging -f    # staging logs, streaming

# Console
kamal app exec "bin/rails console"
kamal app exec -d staging "bin/rails console"

# Migrations
kamal app exec "bin/rails db:migrate"
kamal app exec -d staging "bin/rails db:migrate"

# Rollback
kamal rollback                  # previous version
kamal rollback <git-sha>        # specific version

# Status
kamal details                   # all containers and their state
kamal traefik logs              # proxy logs

# Restart
kamal app boot                  # restart app containers
kamal traefik reboot            # restart proxy
```

---

## What's deferred

- **PR preview environments** — script per-branch deploys later
- **CDN for assets** — Cloudflare proxy gives basic edge caching; DO Spaces CDN for uploads
- **Multi-server** — horizontal scaling when traffic warrants
- **Database read replicas** — single primary is fine early
- **Error tracking** — add Sentry or Honeybadger when in production with real users
- **APM** — add Scout or New Relic when performance tuning matters
- **Infrastructure-as-code** — Terraform for DO resources. Not needed for 2-4 resources
