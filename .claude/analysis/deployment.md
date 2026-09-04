# Analysis: Deployment Infrastructure

## Requirements

| Requirement | Details |
|-------------|---------|
| Rails 8.1 + PostgreSQL | Docker-based, Solid Queue/Cache/Cable (no Redis) |
| Wildcard subdomains | `*.replay.com` — app, play, api, admin, marketing |
| GitHub CI/CD | Deploy on merge to main, ideally preview envs |
| Staging + Production | Separate environments, same infrastructure pattern |
| WebSockets | ActionCable/Solid Cable — persistent connections |
| ActiveStorage | Image uploads for ads, listings, agents |
| SSL | Wildcard cert for all subdomains |
| Cost | Startup-friendly, not enterprise pricing |

## The wildcard subdomain filter

This is the single biggest constraint. Most PaaS platforms **do not support wildcard subdomains**:

| Platform | Wildcard support | Verdict |
|----------|:---:|---------|
| Render | No — manual per-subdomain | Dealbreaker |
| Railway | No — manual per-subdomain | Dealbreaker |
| DO App Platform | No — manual per-subdomain | Dealbreaker |
| Google Cloud Run | No — 60-min WebSocket timeout | Dealbreaker |
| Heroku | Yes, but $200+/mo minimum | Too expensive |
| Fly.io | Partial — works for fixed subdomains, requires API calls for dynamic | Workable but fiddly |
| **Kamal + VPS** | **Yes — you control DNS + Traefik** | **Best fit** |
| AWS ECS/Fargate | Yes, but complex + expensive | Overkill |

**Result: Kamal + VPS is the clear winner.** You own the server, you own the proxy, wildcard subdomains just work.

---

## Kamal + Hetzner vs Kamal + DigitalOcean

| Factor | Hetzner | DigitalOcean |
|--------|---------|-------------|
| **Price (staging + prod)** | ~$25-45/mo | ~$60-120/mo |
| **Managed PostgreSQL** | Hetzner DBaaS (~$25/mo) or self-host ($4/mo) | DO Managed PG ($15/mo basic) |
| **Object Storage** | S3-compatible ($6/mo for 1TB) | DO Spaces ($5/mo) |
| **US Regions** | Ashburn, Hillsboro (newer) | NYC, SFO, + many |
| **Community** | Rails/indie darling in 2025 | Established, more docs |
| **Monitoring** | Basic (need external) | Built-in graphs |
| **Backups** | Manual or snapshot-based | Automated ($1-2/mo) |

**Recommendation: Start with Hetzner.** 2-3x cheaper for equivalent specs. The Rails community has converged on Hetzner + Kamal as the default indie stack. If you later need US-specific compliance or multi-region, DigitalOcean or AWS is an easy migration since Kamal is server-agnostic.

---

## How Kamal works

Kamal is Rails 8's built-in deployment tool. No Kubernetes, no Helm — just Docker + SSH + Traefik.

**Deploy flow:**
1. Build Docker image locally (or in CI)
2. Push to container registry (GHCR)
3. SSH into server
4. Pull new image
5. Start new container, wait for health check (`/up`)
6. Swap Traefik routing to new container
7. Stop old container

**Zero-downtime** by default — Traefik keeps routing to the old container until the new one passes health checks.

**Rollback:** `kamal rollback` pulls the previous image tag. Near-instant.

---

## Proposed infrastructure

### Staging

Single Hetzner CX22 (2 vCPU, 4 GB RAM, ~$5/mo) running:
- Rails web (Puma)
- Solid Queue worker
- PostgreSQL (Kamal accessory)
- Traefik proxy

Domain: `*.staging.replay.com`

### Production

| Component | Server | Cost |
|-----------|--------|------|
| Web + Worker | Hetzner CX32 (4 vCPU, 8 GB) | ~$14/mo |
| PostgreSQL | Hetzner DBaaS or dedicated CX22 | ~$5-25/mo |
| Object Storage | Hetzner S3-compatible or Cloudflare R2 | ~$5/mo |
| **Total** | | **~$25-45/mo** |

Domain: `*.replay.com`

### DNS + SSL

- **DNS**: Cloudflare (free tier) — required for Traefik's DNS-01 challenge
- **SSL**: Let's Encrypt wildcard cert via Cloudflare DNS API
- **Wildcard record**: `*.replay.com → server IP` + `*.staging.replay.com → staging IP`

---

## GitHub Actions CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_PASSWORD: test
        ports: ["5432:5432"]
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bin/rails db:test:prepare
      - run: bundle exec rspec

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
      - run: gem install kamal
      - run: kamal deploy
        env:
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
```

### Staging deploys

Use Kamal destinations:

```bash
kamal deploy -d staging    # deploys to staging server
kamal deploy               # deploys to production
```

Staging can auto-deploy on push to a `staging` branch, or manually via `workflow_dispatch`.

---

## Realistic deploy.yml

```yaml
service: replay-rails
image: ghcr.io/omarvelous/replay-rails

servers:
  web:
    hosts:
      - 157.180.1.10
    labels:
      traefik.http.routers.replay.rule: >
        HostRegexp(`{subdomain:[a-z0-9-]+}.replay.com`) || Host(`replay.com`)
      traefik.http.routers.replay.tls: "true"
      traefik.http.routers.replay.tls.certresolver: letsencrypt
      traefik.http.routers.replay.tls.domains[0].main: replay.com
      traefik.http.routers.replay.tls.domains[0].sans: "*.replay.com"
  worker:
    hosts:
      - 157.180.1.10
    cmd: bin/jobs start

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
  clear:
    RAILS_ENV: production
    SOLID_QUEUE_IN_PUMA: false

accessories:
  postgres:
    image: postgres:17
    host: 157.180.1.10
    env:
      secret:
        - POSTGRES_PASSWORD
      clear:
        POSTGRES_USER: replay
        POSTGRES_DB: replay_production
    volumes:
      - /data/postgres:/var/lib/postgresql/data

traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt:/letsencrypt"
  args:
    entryPoints.websecure.address: ":443"
    certificatesResolvers.letsencrypt.acme.email: ops@replay.com
    certificatesResolvers.letsencrypt.acme.storage: /letsencrypt/acme.json
    certificatesResolvers.letsencrypt.acme.dnsChallenge: true
    certificatesResolvers.letsencrypt.acme.dnsChallenge.provider: cloudflare
  env:
    secret:
      - CF_DNS_API_TOKEN

healthcheck:
  path: /up
  port: 3000

volumes:
  - "/data/storage:/rails/storage"
```

---

## Implementation steps

### Phase 1 — Staging environment

1. Buy a Hetzner CX22 (~$5/mo)
2. Register a domain (or use `staging.replay.com`)
3. Set up Cloudflare DNS with wildcard A record
4. Configure `config/deploy.staging.yml`
5. Run `kamal setup -d staging` — provisions server, installs Docker, starts Traefik + PostgreSQL + app
6. Verify all subdomains work with SSL
7. Test Fire TV Sticks against staging URL

### Phase 2 — GitHub Actions CI/CD

8. Add deploy workflow (test → deploy on merge to main)
9. Add staging deploy workflow (manual trigger or staging branch)
10. Store secrets in GitHub: SSH key, Rails master key, Cloudflare API token

### Phase 3 — Production environment

11. Buy a Hetzner CX32 (~$14/mo)
12. Set up production Cloudflare DNS
13. Configure `config/deploy.yml` (production)
14. Decide on managed PostgreSQL vs accessory
15. Set up Cloudflare R2 or Hetzner Object Storage for ActiveStorage
16. Run `kamal setup` — production is live

### Phase 4 — Operational hardening

17. Automated database backups (pg_dump cron or managed service)
18. Monitoring (Kamal health checks + uptime monitoring)
19. Log aggregation (optional: Papertrail, Logflare)
20. Alerts (server down, deploy failed)

---

## What's deferred

- **Multi-region** — single server per environment is fine until traffic warrants it
- **CDN** — Cloudflare's free tier gives you edge caching for static assets
- **PR preview environments** — Kamal doesn't support this natively. Script it later with per-branch deploys to staging, or use Fly.io for previews only
- **Auto-scaling** — not needed until traffic is consistent and measurable
- **Database replication** — single instance is fine for early stage
