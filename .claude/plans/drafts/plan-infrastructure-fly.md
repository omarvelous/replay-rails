# Plan: Infrastructure with Fly.io (Draft)

## Goal

Deploy RePlay to Fly.io with staging and production environments,
wildcard subdomain support, GitHub CI/CD, and PR preview environments.

## Why Fly.io

- **Fastest path to staging** — `fly launch` + `fly deploy`, no server provisioning
- **PR preview apps** — built-in, spin up per PR with `fly-pr-review-apps` action
- **WebSocket support** — persistent connections, ActionCable works natively
- **Edge routing + TLS** — automatic, no Traefik/Caddy config
- **GitHub Actions** — official `superfly/flyctl-actions`
- **Autostop** — machines stop when idle, staging costs drop to near-zero

## Tradeoffs vs Kamal + DO/Hetzner

| Factor | Fly.io | Kamal + VPS |
|--------|--------|-------------|
| **Setup time** | ~30 minutes | ~2-3 hours |
| **PR previews** | Built-in | DIY scripting |
| **Control** | PaaS (limited) | Full root access |
| **IaC (OpenTofu)** | No provider — CLI only | Full Terraform/OpenTofu |
| **Cost (staging + prod)** | ~$80-120/mo | ~$40-80/mo |
| **WebSockets** | Works, but autostop can interfere | No caveats |
| **Database** | Fly PG (unmanaged) or external | Managed DB or self-host |
| **Wildcard subdomains** | Cert works, $1/mo extra | Native, free via Let's Encrypt |

**Key limitation**: No OpenTofu/Terraform provider. Infrastructure is managed via `flyctl` CLI and `fly.toml` committed to git. If IaC is a hard requirement, use the Kamal + DO plan instead.

---

## Stack

| Component | Tool | Cost |
|-----------|------|------|
| Hosting | Fly.io Machines | $20-50/mo per env |
| Database | Neon (managed Postgres) | Free tier (staging) / $19/mo (prod) |
| File Storage | Tigris (Fly's S3-compatible) | ~$1-5/mo |
| DNS | Cloudflare (free) | Free |
| SSL | Fly.io managed (Let's Encrypt) | $1/mo wildcard |
| CI/CD | GitHub Actions + flyctl | Free |
| PR Previews | fly-pr-review-apps | Pay-per-use (autostop) |

### Why Neon over Fly Postgres

Fly Postgres is **not managed** — it's Postgres in a VM you maintain. You handle crashes, upgrades, and backup validation. Neon is truly managed:
- Serverless autoscaling
- Per-PR database branching (perfect for preview apps)
- Free tier covers staging
- Connection pooling built in

---

## Fly.io app structure

```
replay-production     — production web + worker
replay-staging        — staging web + worker
replay-pr-<number>    — ephemeral PR preview apps (auto-created/destroyed)
```

Each app has its own secrets, database connection, and domain config.

---

## Configuration

### fly.toml (production)

```toml
app = "replay-production"
primary_region = "iad"

[build]
  dockerfile = "Dockerfile"

[deploy]
  release_command = "bin/rails db:prepare"
  strategy = "rolling"

[processes]
  app = "bin/rails server -p 3000 -b 0.0.0.0"
  worker = "bundle exec rake solid_queue:start"

[env]
  RAILS_ENV = "production"
  RAILS_LOG_TO_STDOUT = "true"
  RAILS_SERVE_STATIC_FILES = "true"
  PORT = "3000"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 1
  processes = ["app"]

  [http_service.concurrency]
    type = "requests"
    hard_limit = 200
    soft_limit = 150

[[vm]]
  size = "shared-cpu-2x"
  memory = "1gb"
  processes = ["app"]

[[vm]]
  size = "shared-cpu-1x"
  memory = "512mb"
  processes = ["worker"]

[[statics]]
  guest_path = "/rails/public"
  url_prefix = "/"
```

### fly.staging.toml

```toml
app = "replay-staging"
primary_region = "iad"

[build]
  dockerfile = "Dockerfile"

[deploy]
  release_command = "bin/rails db:prepare"

[processes]
  app = "bin/rails server -p 3000 -b 0.0.0.0"
  worker = "bundle exec rake solid_queue:start"

[env]
  RAILS_ENV = "staging"
  RAILS_LOG_TO_STDOUT = "true"
  RAILS_SERVE_STATIC_FILES = "true"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0
  processes = ["app"]

[[vm]]
  size = "shared-cpu-1x"
  memory = "512mb"
  processes = ["app"]

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"
  processes = ["worker"]
```

Staging uses autostop — machines sleep when idle, costs drop to near-zero.

### Storage config

```yaml
# config/storage.yml
tigris:
  service: S3
  endpoint: https://fly.storage.tigris.dev
  access_key_id: <%= ENV["AWS_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["AWS_SECRET_ACCESS_KEY"] %>
  region: auto
  bucket: <%= ENV["BUCKET_NAME"] %>
```

### Staging environment

```ruby
# config/environments/staging.rb
require_relative "production"

Rails.application.configure do
  config.action_mailer.default_url_options = {
    host: "app.staging.replaytv.co",
    protocol: "https"
  }
end
```

---

## Domain + SSL setup

### Allocate IPs

```bash
# Production
fly ips allocate-v4 --app replay-production
fly ips allocate-v6 --app replay-production

# Staging
fly ips allocate-v4 --app replay-staging
fly ips allocate-v6 --app replay-staging
```

### Add certificates

```bash
# Production — wildcard + root
fly certs add "replaytv.co" --app replay-production
fly certs add "*.replaytv.co" --app replay-production
fly certs add "rply.tv" --app replay-production

# Staging
fly certs add "staging.replaytv.co" --app replay-staging
fly certs add "*.staging.replaytv.co" --app replay-staging
```

For wildcard certs, Fly requires a CNAME for the DNS-01 challenge:

```
_acme-challenge.replaytv.co  CNAME  replaytv.co.<fly-validation>.fly.dev
```

### Cloudflare DNS records

```
# Production
A    replaytv.co           → <fly-ipv4>        (Proxied)
AAAA replaytv.co           → <fly-ipv6>        (Proxied)
A    *.replaytv.co         → <fly-ipv4>        (DNS only — free plan can't proxy wildcard)
A    rply.tv               → <fly-ipv4>        (Proxied)

# Staging
A    staging.replaytv.co   → <staging-ipv4>    (Proxied)
A    *.staging.replaytv.co → <staging-ipv4>    (DNS only)
```

Set Cloudflare SSL mode to **Full (Strict)**.

---

## GitHub Actions CI/CD

### CI (all PRs)

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

### Deploy staging

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
    concurrency: deploy-staging
    steps:
      - uses: actions/checkout@v4
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --config fly.staging.toml --app replay-staging --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### Deploy production

```yaml
# .github/workflows/deploy-production.yml
name: Deploy Production
on:
  push:
    branches: [main]

jobs:
  test:
    # Same as CI test job
    ...

  deploy:
    needs: test
    runs-on: ubuntu-latest
    concurrency: deploy-production
    steps:
      - uses: actions/checkout@v4
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### PR preview apps

```yaml
# .github/workflows/preview.yml
name: Preview
on:
  pull_request:
    types: [opened, reopened, synchronize, closed]

jobs:
  preview:
    runs-on: ubuntu-latest
    concurrency: preview-${{ github.event.pull_request.number }}
    steps:
      - uses: actions/checkout@v4
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - uses: superfly/fly-pr-review-apps@1.2.1
        with:
          name: replay-pr-${{ github.event.pull_request.number }}
          config: fly.staging.toml
          region: iad
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

Preview apps auto-destroy when the PR is closed/merged. Each gets its own URL: `replay-pr-42.fly.dev`.

For database per PR, use Neon branching:

```yaml
      - name: Create Neon branch
        if: github.event.action != 'closed'
        run: |
          BRANCH=$(neonctl branches create --project-id $NEON_PROJECT_ID --name pr-${{ github.event.pull_request.number }} --output json | jq -r '.connection_uri')
          flyctl secrets set DATABASE_URL="$BRANCH" --app replay-pr-${{ github.event.pull_request.number }}
```

---

## Build order

### Phase 1 — Accounts and prerequisites

1. Create Fly.io account: `fly auth signup`
2. Install flyctl: `brew install flyctl`
3. Create Neon account, create a project for RePlay
4. Create Tigris bucket: `fly storage create`
5. Add domains to Cloudflare: `replaytv.co` and `rply.tv`
6. Create Fly API token: `fly tokens create deploy -x 999999h`

### Phase 2 — Staging app

7. Create staging app: `fly apps create replay-staging`
8. Create `fly.staging.toml` with staging config
9. Set secrets:
   ```bash
   fly secrets set \
     RAILS_MASTER_KEY=<key> \
     DATABASE_URL=<neon-staging-url> \
     AWS_ACCESS_KEY_ID=<tigris-key> \
     AWS_SECRET_ACCESS_KEY=<tigris-secret> \
     BUCKET_NAME=replay-staging \
     --app replay-staging
   ```
10. Create `config/environments/staging.rb`
11. Deploy: `fly deploy --config fly.staging.toml --app replay-staging --remote-only`
12. Run migrations: `fly ssh console --app replay-staging -C "bin/rails db:prepare"`
13. Seed data: `fly ssh console --app replay-staging -C "bin/rails db:seed"`

### Phase 3 — Domains and SSL

14. Allocate IPs for staging app
15. Add certs: `fly certs add "*.staging.replaytv.co" --app replay-staging`
16. Add Cloudflare DNS records (A + wildcard)
17. Add ACME challenge CNAME for wildcard cert
18. Verify all subdomains work with SSL:
    - `https://staging.replaytv.co`
    - `https://app.staging.replaytv.co`
    - `https://play.staging.replaytv.co/players/new`
    - `https://api.staging.replaytv.co/players`
    - `https://admin.staging.replaytv.co`

### Phase 4 — GitHub Actions CI/CD

19. Store `FLY_API_TOKEN` in GitHub repo secrets
20. Create `.github/workflows/ci.yml` — test suite on PRs
21. Create `.github/workflows/deploy-staging.yml` — deploy on push to staging branch
22. Create `.github/workflows/deploy-production.yml` — deploy on push to main
23. Test: push to staging branch, verify auto-deploy

### Phase 5 — PR preview apps

24. Create `.github/workflows/preview.yml` with `fly-pr-review-apps`
25. Set up Neon branching for per-PR databases (optional, can use shared staging DB)
26. Test: open a PR, verify preview app spins up at `replay-pr-<number>.fly.dev`
27. Merge PR, verify preview app is destroyed

### Phase 6 — Device testing

28. Point Fire TV Stick at `https://play.staging.replaytv.co/players/new`
29. Pair via `https://app.staging.replaytv.co`
30. Verify: pairing → content plays → playlist push → heartbeat
31. Test Raspberry Pi and Signage Stick
32. Run 24/7 for 1 week

### Phase 7 — Production

33. Create production app: `fly apps create replay-production`
34. Write `fly.toml` with production config (autostop off, min 1 machine)
35. Create Neon production database (or Fly Managed Postgres)
36. Create production Tigris bucket
37. Set production secrets
38. Deploy: `fly deploy --remote-only`
39. Allocate IPs, add certs for `replaytv.co`, `*.replaytv.co`, `rply.tv`
40. Cloudflare DNS for production
41. Verify all subdomains, SSL, WebSockets, uploads

### Phase 8 — Operational hardening

42. **Database backups**: Neon handles automatically (point-in-time recovery)
43. **Uptime monitoring**: UptimeRobot or BetterUptime — ping `/up` on each subdomain
44. **Logging**: `fly logs --app replay-production` for live; add Logflare/Papertrail for retention
45. **Alerts**: Fly.io has built-in alerts for machine crashes; add Slack webhook
46. **Scaling**: `fly scale count app=2 worker=1` for horizontal web scaling
47. **Rollback**: `fly releases rollback --app replay-production`

---

## Cost summary

### Staging only

| Item | Monthly |
|------|---------|
| Fly machines (autostop, minimal usage) | ~$5-10 |
| Neon free tier | $0 |
| Tigris storage | ~$1 |
| Wildcard cert | $1 |
| Dedicated IPv4 | $2 |
| **Total** | **~$10-15/mo** |

### Staging + Production

| Item | Monthly |
|------|---------|
| Staging (autostop) | ~$10 |
| Production (2 machines always on) | ~$25-40 |
| Neon (staging free + prod $19) | $19 |
| Tigris (2 buckets) | ~$3 |
| Certs + IPs | ~$6 |
| **Total** | **~$65-80/mo** |

---

## Fly CLI cheat sheet

```bash
# Deploy
fly deploy --remote-only                           # production
fly deploy --config fly.staging.toml --app replay-staging --remote-only  # staging

# Logs
fly logs --app replay-production
fly logs --app replay-staging

# Console
fly ssh console --app replay-production -C "bin/rails console"

# Secrets
fly secrets set KEY=value --app replay-production
fly secrets list --app replay-production

# Scale
fly scale count app=2 worker=1 --app replay-production
fly scale vm shared-cpu-2x --app replay-production

# Status
fly status --app replay-production
fly machines list --app replay-production

# Rollback
fly releases --app replay-production
fly releases rollback --app replay-production
```

---

## What's deferred

- **Multi-region** — Fly excels at this but not needed yet
- **Auto-scaling** — manual `fly scale count` is fine early
- **OpenTofu/IaC** — no Fly provider. `fly.toml` in git + CLI is the IaC substitute
- **Custom error pages** — Fly shows its own 502/503 pages by default
- **Log retention** — add Papertrail or Logflare when needed
- **CDN** — Cloudflare proxy handles edge caching for proxied domains
