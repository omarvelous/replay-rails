# Plan: Infrastructure with Render (Draft)

## Goal

Deploy RePlay to Render with staging and production environments,
subdomain support, GitHub CI/CD, and PR preview environments.
Cloudflare DNS and SSL managed via OpenTofu.

## Why Render

- **Zero config deploys** — connect GitHub repo, Render builds and deploys
- **PR previews** — built-in, auto-deploy per PR
- **Managed PostgreSQL** — truly managed, daily backups, no DBA work
- **Native GitHub integration** — auto-deploy on push, no Actions workflow needed
- **Free SSL** — automatic Let's Encrypt per domain
- **Background workers** — first-class support for Solid Queue
- **Persistent disk** — optional, for ActiveStorage local fallback

## The subdomain constraint

Render **does not support wildcard domains**. Each subdomain must be
added individually in the Render dashboard. For RePlay's 5 fixed
subdomains, this is manageable:

```
replaytv.co              → Render web service
app.replaytv.co          → same service
admin.replaytv.co        → same service
play.replaytv.co         → same service
api.replaytv.co          → same service
rply.tv                  → same service
```

6 custom domains, added once. If you later need dynamic per-tenant
subdomains, Render won't work — but for the current fixed set, it's fine.

**SSL**: Render issues individual Let's Encrypt certs per domain
automatically. No wildcard cert needed since each domain is explicit.

---

## Stack

| Component | Tool | Cost |
|-----------|------|------|
| Web service | Render Web Service (Docker) | $7-25/mo |
| Worker | Render Background Worker | $7-25/mo |
| Database | Render Managed PostgreSQL | $7-20/mo |
| File storage | Cloudflare R2 | $0-5/mo |
| DNS + SSL settings | Cloudflare via OpenTofu | Free |
| SSL certs | Render (auto Let's Encrypt) | Free |
| CI/CD | Render native (GitHub integration) | Free |
| PR previews | Render Preview Environments | Pay-per-use |
| IaC | OpenTofu (Cloudflare provider) | Free |

---

## Configuration

### render.yaml (Infrastructure as Code)

Render uses `render.yaml` (Blueprint) with Projects and Environments.
One file defines all services across staging and production:

```yaml
# render.yaml
projects:
  - name: replay
    environments:
      # ── Production ──────────────────────────────────
      - name: production
        databases:
          - name: replay-db
            plan: starter
            databaseName: replay_production
            user: replay
            region: ohio

        envVarGroups:
          - name: replay-shared
            envVars:
              - key: RAILS_LOG_TO_STDOUT
                value: "true"
              - key: RAILS_SERVE_STATIC_FILES
                value: "true"
              - key: RAILS_MASTER_KEY
                sync: false
              - key: R2_ACCESS_KEY_ID
                sync: false
              - key: R2_SECRET_ACCESS_KEY
                sync: false
              - key: R2_ENDPOINT
                sync: false

        services:
          - type: web
            name: replay-web
            runtime: docker
            plan: starter
            region: ohio
            branch: main
            healthCheckPath: /up
            envVars:
              - key: RAILS_ENV
                value: production
              - key: DATABASE_URL
                fromDatabase:
                  name: replay-db
                  property: connectionString
              - key: R2_BUCKET
                value: replay-production
              - fromGroup: replay-shared
            buildFilter:
              paths:
                - app/**
                - config/**
                - db/**
                - lib/**
                - Gemfile*
                - Dockerfile
            previews:
              plan: starter
              generation: manual

          - type: worker
            name: replay-worker
            runtime: docker
            plan: starter
            region: ohio
            branch: main
            dockerCommand: bundle exec rake solid_queue:start
            envVars:
              - key: RAILS_ENV
                value: production
              - key: DATABASE_URL
                fromDatabase:
                  name: replay-db
                  property: connectionString
              - fromGroup: replay-shared

        networking:
          isolation: enabled

      # ── Staging ─────────────────────────────────────
      - name: staging
        databases:
          - name: replay-staging-db
            plan: starter
            databaseName: replay_staging
            user: replay
            region: ohio
            previewPlan: starter

        envVarGroups:
          - name: replay-staging-shared
            envVars:
              - key: RAILS_LOG_TO_STDOUT
                value: "true"
              - key: RAILS_SERVE_STATIC_FILES
                value: "true"
              - key: RAILS_MASTER_KEY
                sync: false
              - key: R2_ACCESS_KEY_ID
                sync: false
              - key: R2_SECRET_ACCESS_KEY
                sync: false
              - key: R2_ENDPOINT
                sync: false

        services:
          - type: web
            name: replay-staging-web
            runtime: docker
            plan: starter
            region: ohio
            branch: staging
            healthCheckPath: /up
            envVars:
              - key: RAILS_ENV
                value: staging
              - key: DATABASE_URL
                fromDatabase:
                  name: replay-staging-db
                  property: connectionString
              - key: R2_BUCKET
                value: replay-staging
              - fromGroup: replay-staging-shared
            previews:
              plan: starter
              generation: automatic

          - type: worker
            name: replay-staging-worker
            runtime: docker
            plan: starter
            region: ohio
            branch: staging
            dockerCommand: bundle exec rake solid_queue:start
            envVars:
              - key: RAILS_ENV
                value: staging
              - key: DATABASE_URL
                fromDatabase:
                  name: replay-staging-db
                  property: connectionString
              - fromGroup: replay-staging-shared

    previewsEnabled: true
    previewsExpireAfterDays: 3
```

### How the environments work

- **Production** deploys from `main` branch with manual preview generation
- **Staging** deploys from `staging` branch with automatic PR previews
- Each environment has its own database, env var group, and R2 bucket
- Secrets (`sync: false`) are set per-environment in the Render dashboard after Blueprint sync
- Network isolation is enabled on production for security
- PR previews spin up under the staging environment with their own ephemeral database

### Storage config

```yaml
# config/storage.yml
cloudflare:
  service: S3
  endpoint: <%= ENV["R2_ENDPOINT"] %>
  access_key_id: <%= ENV["R2_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["R2_SECRET_ACCESS_KEY"] %>
  bucket: <%= ENV["R2_BUCKET"] %>
  region: auto
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

## OpenTofu — Cloudflare + R2

Render manages compute (web, worker, database). Cloudflare manages
DNS, SSL settings, and R2 storage — provisioned via OpenTofu.

### Directory structure

```
infrastructure/
├── modules/
│   └── cloudflare/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   └── production/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── outputs.tf
├── providers.tf
├── versions.tf
└── README.md
```

### providers.tf

```hcl
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
```

### Cloudflare module

```hcl
# infrastructure/modules/cloudflare/main.tf

# DNS records — one per subdomain pointing to Render
resource "cloudflare_dns_record" "root" {
  zone_id = var.zone_id
  name    = var.domain
  content = var.render_cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_dns_record" "app" {
  zone_id = var.zone_id
  name    = "app.${var.domain}"
  content = var.render_cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_dns_record" "admin" {
  zone_id = var.zone_id
  name    = "admin.${var.domain}"
  content = var.render_cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_dns_record" "play" {
  zone_id = var.zone_id
  name    = "play.${var.domain}"
  content = var.render_cname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_dns_record" "api" {
  zone_id = var.zone_id
  name    = "api.${var.domain}"
  content = var.render_cname
  type    = "CNAME"
  proxied = true
}

# SSL settings
resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.zone_id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "always_https" {
  zone_id    = var.zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "min_tls" {
  zone_id    = var.zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

# R2 bucket
resource "cloudflare_r2_bucket" "storage" {
  account_id = var.cloudflare_account_id
  name       = var.r2_bucket_name
  location   = "ENAM"
}
```

```hcl
# infrastructure/modules/cloudflare/variables.tf
variable "zone_id" {}
variable "domain" {}
variable "render_cname" {}
variable "cloudflare_account_id" {}
variable "r2_bucket_name" {}
```

### Staging environment

```hcl
# infrastructure/environments/staging/main.tf
terraform {
  backend "s3" {
    bucket                      = "replay-tofu-state"
    key                         = "staging/terraform.tfstate"
    region                      = "auto"
    endpoints                   = { s3 = "https://<account_id>.r2.cloudflarestorage.com" }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

module "cloudflare" {
  source                = "../../modules/cloudflare"
  zone_id               = var.cloudflare_zone_id
  domain                = "staging.replaytv.co"
  render_cname          = "replay-staging-web.onrender.com"
  cloudflare_account_id = var.cloudflare_account_id
  r2_bucket_name        = "replay-staging"
}
```

### Production environment

```hcl
# infrastructure/environments/production/main.tf
terraform {
  backend "s3" {
    bucket                      = "replay-tofu-state"
    key                         = "production/terraform.tfstate"
    region                      = "auto"
    endpoints                   = { s3 = "https://<account_id>.r2.cloudflarestorage.com" }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

module "cloudflare" {
  source                = "../../modules/cloudflare"
  zone_id               = var.cloudflare_zone_id
  domain                = "replaytv.co"
  render_cname          = "replay-web.onrender.com"
  cloudflare_account_id = var.cloudflare_account_id
  r2_bucket_name        = "replay-production"
}

# Short domain for QR scan URLs
resource "cloudflare_dns_record" "rply_tv" {
  zone_id = var.rply_tv_zone_id
  name    = "rply.tv"
  content = "replay-web.onrender.com"
  type    = "CNAME"
  proxied = true
}
```

### State management

Store OpenTofu state in a Cloudflare R2 bucket (S3-compatible).
Create the state bucket manually first (chicken-and-egg):

```bash
# One-time: create state bucket via wrangler or Cloudflare dashboard
wrangler r2 bucket create replay-tofu-state
```

### Common operations

```bash
cd infrastructure/environments/staging

# Initialize
tofu init

# Preview changes
tofu plan

# Apply
tofu apply

# Show current state
tofu show
```

### Gitignore additions

```gitignore
# OpenTofu
infrastructure/**/.terraform/
infrastructure/**/*.tfstate
infrastructure/**/*.tfstate.backup
infrastructure/**/*.tfvars
!infrastructure/**/variables.tf
*.tfplan
```

---

## Domain + SSL setup

### Render dashboard

Add each custom domain in the Render service settings:

1. `replaytv.co`
2. `app.replaytv.co`
3. `admin.replaytv.co`
4. `play.replaytv.co`
5. `api.replaytv.co`
6. `rply.tv`

Render provides a CNAME target for each (e.g., `replay-web.onrender.com`).
This CNAME is used in the OpenTofu Cloudflare module above.

### Cloudflare DNS (managed by OpenTofu)

These records are created by `tofu apply` — not manually in the dashboard:

```
# Production (via infrastructure/environments/production/)
CNAME  replaytv.co           → replay-web.onrender.com    (Proxied)
CNAME  app.replaytv.co       → replay-web.onrender.com    (Proxied)
CNAME  admin.replaytv.co     → replay-web.onrender.com    (Proxied)
CNAME  play.replaytv.co      → replay-web.onrender.com    (Proxied)
CNAME  api.replaytv.co       → replay-web.onrender.com    (Proxied)
CNAME  rply.tv               → replay-web.onrender.com    (Proxied)

# Staging (via infrastructure/environments/staging/)
CNAME  staging.replaytv.co       → replay-staging-web.onrender.com
CNAME  app.staging.replaytv.co   → replay-staging-web.onrender.com
CNAME  admin.staging.replaytv.co → replay-staging-web.onrender.com
CNAME  play.staging.replaytv.co  → replay-staging-web.onrender.com
CNAME  api.staging.replaytv.co   → replay-staging-web.onrender.com
```

SSL mode (Full Strict), Always HTTPS, and min TLS 1.2 are also set by OpenTofu.

Render auto-issues a Let's Encrypt cert per domain after DNS verification.

---

## CI/CD

### Native GitHub integration (no Actions needed)

Render connects to your GitHub repo directly:
- **Auto-deploy on push** to the configured branch
- **PR previews** — Render creates an ephemeral environment per PR
- Build logs visible in the Render dashboard

No `.github/workflows/` needed for deployment.

### Optional: CI with GitHub Actions

Render doesn't run your test suite. Add a GitHub Actions CI workflow
for tests + linting:

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

Render deploys happen in parallel — it doesn't wait for CI to pass.
To enforce tests before deploy, enable **PR preview only** (not
auto-deploy to production) and merge only after CI passes.

---

## PR preview environments

Render's preview environments are defined in `render.yaml` with
`previewsEnabled: true`. When a PR is opened:

1. Render creates a new web service + worker + database
2. Runs `db:prepare` (migrations + seed if configured)
3. Preview is available at `replay-web-pr-42.onrender.com`
4. Each subdomain gets a preview variant (manual domain add not needed — use the `.onrender.com` URL)
5. On PR close/merge, the preview is destroyed

**Database per PR**: Render creates a separate PostgreSQL instance
for each preview environment automatically from the `render.yaml`
database definition.

**Limitation**: Preview apps use `.onrender.com` URLs, not your custom
subdomains. Subdomain routing won't work properly unless you configure
`tld_length` or use a host-based routing approach in the preview.

---

## Build order

### Phase 1 — Accounts and prerequisites

1. Create Render account, connect GitHub repo
2. Create Cloudflare account, add `replaytv.co` and `rply.tv` zones
3. Create Cloudflare tokens (two separate tokens — see below)
4. Install OpenTofu: `brew install opentofu`

#### Cloudflare API token (for OpenTofu — DNS + zone settings)

This token lets OpenTofu manage DNS records and SSL settings.

1. Go to **Cloudflare Dashboard → Profile → API Tokens → Create Token**
2. Use the **"Edit zone DNS"** template, or create a custom token with:
   - **Permissions**:
     - Zone → DNS → Edit
     - Zone → Zone Settings → Edit
   - **Zone Resources**: Include → Specific zone → `replaytv.co`
   - Add a second zone resource: Include → Specific zone → `rply.tv`
3. Click **Continue to summary → Create Token**
4. Copy the token — you won't see it again
5. Save as `CLOUDFLARE_API_TOKEN` (used in OpenTofu and GitHub secrets)

You also need your **Zone IDs** (not secret, just identifiers):
- Go to each domain's Overview page in Cloudflare
- Zone ID is in the right sidebar under "API"
- Save as `CLOUDFLARE_ZONE_ID_REPLAYTV` and `CLOUDFLARE_ZONE_ID_RPLY`

And your **Account ID**:
- Same sidebar on any domain's Overview page
- Save as `CLOUDFLARE_ACCOUNT_ID`

#### R2 API token (for ActiveStorage — S3-compatible access)

This token is separate from the API token above. It provides S3-compatible
credentials (Access Key ID + Secret Access Key) for uploading files.

1. Go to **Cloudflare Dashboard → R2 Object Storage**
2. In the right sidebar under **Account Details**, click **Manage R2 API Tokens**
3. Click **Create API Token**
4. Configure:
   - **Permissions**: Object Read & Write
   - **Scope**: Apply to specific buckets only → select your buckets
     (create the buckets first if they don't exist yet — or use
     "Apply to all buckets in account" to start, scope later)
   - **TTL**: Optional, leave blank for no expiry
5. Click **Create API Token**
6. Copy both values immediately — **you cannot see the Secret Access Key again**:
   - **Access Key ID** → save as `R2_ACCESS_KEY_ID`
   - **Secret Access Key** → save as `R2_SECRET_ACCESS_KEY`

Your R2 endpoint is: `https://<CLOUDFLARE_ACCOUNT_ID>.r2.cloudflarestorage.com`

#### State bucket (for OpenTofu — created manually)

The OpenTofu state bucket is a chicken-and-egg problem — you can't
provision the bucket that holds your state with state stored in that
bucket. Create it manually first:

1. Go to **Cloudflare Dashboard → R2 Object Storage → Create Bucket**
2. Name: `replay-tofu-state`
3. Location: **Automatic** (or ENAM for US East)
4. Click **Create Bucket**

This bucket is accessed using the same R2 API token created above.

### Phase 2 — OpenTofu bootstrap

5. Create `infrastructure/` directory structure
6. Write `providers.tf` and `versions.tf` (Cloudflare provider)
7. Create state bucket manually: R2 bucket `replay-tofu-state` via Cloudflare dashboard
8. Write `modules/cloudflare/` — DNS records, SSL settings, R2 bucket
9. Run `tofu init`

### Phase 3 — Staging infrastructure (OpenTofu + Render)

10. Write `infrastructure/environments/staging/` config
11. Run `tofu plan` — review DNS records, SSL settings, R2 bucket
12. Run `tofu apply` — provisions Cloudflare resources
13. Create staging services in Render via `render.yaml` Blueprint (web + worker + database)
14. Set environment variables in Render (RAILS_MASTER_KEY, R2 credentials)
15. Add staging custom domains in Render dashboard:
    - `staging.replaytv.co`
    - `app.staging.replaytv.co`
    - `play.staging.replaytv.co`
    - `api.staging.replaytv.co`
    - `admin.staging.replaytv.co`
16. Render auto-deploys from `staging` branch
17. Run migrations via Render Shell: `bin/rails db:prepare`
18. Seed data: `bin/rails db:seed`
19. Verify SSL certs issued for all domains
20. Verify all subdomains route correctly

### Phase 4 — GitHub Actions CI

21. Create `.github/workflows/ci.yml` for test suite on PRs
22. Test: push to staging, verify Render auto-deploys + CI passes

### Phase 5 — PR previews

23. Ensure `previewsEnabled: true` in `render.yaml`
24. Open a test PR, verify preview spins up at `.onrender.com`
25. Note: preview uses `.onrender.com` URL — subdomain routing may need `tld_length` adjustment

### Phase 6 — Device testing

26. Point Fire TV Stick at `https://play.staging.replaytv.co/players/new`
27. Pair via `https://app.staging.replaytv.co`
28. Verify full flow: pairing → content plays → playlist push → heartbeat
29. Test Raspberry Pi and Signage Stick
30. Run 24/7 for 1 week

### Phase 7 — Production

31. Write `infrastructure/environments/production/` config
32. Run `tofu apply` — provisions production DNS, SSL, R2 bucket
33. Create production Render services (higher plans) via `render.yaml`
34. Add production custom domains (6 domains) in Render dashboard
35. Set production environment variables
36. Configure Render to auto-deploy production from `main` branch
37. Verify all subdomains, SSL, WebSockets, uploads

### Phase 8 — Operational hardening

38. **Database backups**: Render Managed PG includes daily automatic backups
39. **Uptime monitoring**: UptimeRobot or BetterUptime on each subdomain's `/up`
40. **Logging**: Render provides log streams; add Papertrail for retention
41. **Scaling**: Adjust plan size in dashboard or `render.yaml`
42. **Rollback**: Render keeps previous deploys; rollback via dashboard
43. **Infra CI**: Add `tofu plan` to PR workflow for infra changes

---

## Cost summary

### Staging only

| Item | Monthly |
|------|---------|
| Web service (Starter) | $7 |
| Worker (Starter) | $7 |
| Managed PostgreSQL (Starter) | $7 |
| Cloudflare R2 | ~$1 |
| **Total** | **~$22/mo** |

### Staging + Production

| Item | Monthly |
|------|---------|
| Staging (web + worker + DB) | $21 |
| Production web (Standard) | $25 |
| Production worker (Standard) | $25 |
| Production PostgreSQL (Standard) | $20 |
| Cloudflare R2 (2 buckets) | ~$3 |
| **Total** | **~$94/mo** |

---

## Comparison to other plans

| Factor | Render | Fly.io | Kamal + DO |
|--------|--------|--------|------------|
| **Setup time** | ~20 min | ~30 min | ~2-3 hrs |
| **Wildcard subdomains** | No (add each) | Yes ($1/mo) | Yes (free) |
| **PR previews** | Built-in | Built-in | DIY |
| **IaC** | render.yaml | fly.toml (no Terraform) | OpenTofu |
| **Database** | Fully managed | Neon or Fly PG | DO Managed PG |
| **WebSockets** | Yes | Yes | Yes |
| **Staging cost** | ~$22/mo | ~$10-15/mo | ~$32/mo |
| **Total (stg + prod)** | ~$94/mo | ~$65-80/mo | ~$76-100/mo |
| **Operational burden** | Lowest | Low | Medium |
| **Future flexibility** | Limited | Moderate | Highest |

### Render's sweet spot

Render is the right choice if:
- Your subdomains are a fixed, known set (they are today)
- You want the absolute lowest operational burden
- You value `render.yaml` as a simple IaC format
- PR previews with auto-provisioned databases are important

### Render's limitations

- Adding a new subdomain requires a manual step in the dashboard
- No wildcard cert — each domain gets its own cert
- No SSH access to the runtime (use Render Shell instead)
- Preview apps don't have custom subdomains (use `.onrender.com`)
- Auto-deploy doesn't wait for CI — you need to enforce via branch protection

---

## What's deferred

- **Dynamic subdomains** — if you add per-tenant subdomains, migrate to Fly.io or Kamal
- **CDN** — Cloudflare proxy handles edge caching for proxied domains
- **Custom error pages** — Render shows its own 502/503 pages
- **Log retention** — add Papertrail or Logflare when needed
- **Horizontal scaling** — Render supports it but costs add up fast
