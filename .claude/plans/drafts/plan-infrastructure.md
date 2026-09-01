# Plan: Infrastructure Provisioning with OpenTofu (Draft)

## Goal

Provision all cloud infrastructure as code using OpenTofu. This plan
covers creating and managing resources on DigitalOcean and Cloudflare.
Deployment (Kamal) is handled separately — this plan creates the
infrastructure that Kamal deploys to.

## Why OpenTofu

- Drop-in Terraform replacement (same HCL, same providers, same workflow)
- Fully open source (MPL 2.0) — no BSL license risk
- Built-in state encryption (no wrapper needed)
- Provider `for_each` for DRY environment configs
- DO + Cloudflare providers work identically to Terraform
- Community has converged on OpenTofu for new projects in 2025-2026

## What OpenTofu manages vs what Kamal manages

| OpenTofu (infrastructure) | Kamal (deployment) |
|--------------------------|-------------------|
| DigitalOcean Droplets | Docker image build + push |
| DO Managed PostgreSQL | SSH into servers |
| DO Spaces buckets | Start/stop containers |
| DO Firewalls + VPC | Traefik proxy + SSL termination |
| Cloudflare DNS records | Health checks |
| Cloudflare SSL settings | Zero-downtime deploy |
| Cloudflare page rules | Rollbacks |

OpenTofu runs once to create infrastructure (and again when infra changes).
Kamal runs on every deploy.

---

## Resources to provision

### DigitalOcean

| Resource | Staging | Production |
|----------|---------|------------|
| Droplet | CX Basic $12/mo (2 GB, 1 vCPU) | CX Basic $24-48/mo (4 GB, 2 vCPU) |
| Managed PostgreSQL | Basic $15/mo | Basic $15/mo |
| Spaces bucket | `replay-staging` | `replay-production` |
| Spaces key pair | For ActiveStorage | For ActiveStorage |
| VPC | Shared VPC per region | Same |
| Firewall | Allow 80, 443, 22 | Allow 80, 443, 22 (restrict SSH to deploy IPs) |
| SSH key | Deploy key registered | Same |

### Cloudflare

| Resource | Staging | Production |
|----------|---------|------------|
| DNS A record (root) | `staging.replaytv.co → staging IP` | `replaytv.co → prod IP` |
| DNS A record (wildcard) | `*.staging.replaytv.co → staging IP` | `*.replaytv.co → prod IP` |
| DNS A record (short domain) | — | `rply.tv → prod IP` |
| SSL mode | Full (strict) | Full (strict) |
| Always Use HTTPS | On | On |

---

## Directory structure

```
infrastructure/
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
├── modules/
│   ├── droplet/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── spaces/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── firewall/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── cloudflare/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── providers.tf
├── versions.tf
└── README.md
```

Modules are reusable across staging and production. Each environment
directory holds the specific config (sizes, domain, region).

---

## State management

Store OpenTofu state in a DigitalOcean Spaces bucket:

```hcl
# infrastructure/environments/staging/main.tf
terraform {
  backend "s3" {
    endpoint                    = "https://nyc3.digitaloceanspaces.com"
    bucket                      = "replay-tofu-state"
    key                         = "staging/terraform.tfstate"
    region                      = "us-east-1"  # required but ignored by DO
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
```

Create the state bucket manually first (chicken-and-egg — can't provision
the bucket that holds your state with the state stored in that bucket).

---

## Example module: Droplet

```hcl
# infrastructure/modules/droplet/main.tf
resource "digitalocean_droplet" "web" {
  name     = var.name
  image    = "ubuntu-24-04-x64"
  size     = var.size
  region   = var.region
  vpc_uuid = var.vpc_id
  ssh_keys = var.ssh_key_ids

  tags = [var.environment]
}

resource "digitalocean_reserved_ip" "web" {
  region = var.region
}

resource "digitalocean_reserved_ip_assignment" "web" {
  ip_address = digitalocean_reserved_ip.web.ip_address
  droplet_id = digitalocean_droplet.web.id
}
```

Reserved IP means the droplet can be destroyed and recreated without
changing DNS records.

## Example module: Cloudflare DNS

```hcl
# infrastructure/modules/cloudflare/main.tf
resource "cloudflare_dns_record" "root" {
  zone_id = var.zone_id
  name    = var.domain
  content = var.server_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_dns_record" "wildcard" {
  zone_id = var.zone_id
  name    = "*.${var.domain}"
  content = var.server_ip
  type    = "A"
  proxied = false  # Wildcard can't be proxied on free plan
}

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
```

## Example environment config

```hcl
# infrastructure/environments/staging/main.tf
module "droplet" {
  source      = "../../modules/droplet"
  name        = "replay-staging"
  size        = "s-1vcpu-2gb"
  region      = "nyc1"
  vpc_id      = digitalocean_vpc.main.id
  ssh_key_ids = [digitalocean_ssh_key.deploy.id]
  environment = "staging"
}

module "database" {
  source  = "../../modules/database"
  name    = "replay-staging-db"
  size    = "db-s-1vcpu-1gb"
  region  = "nyc1"
  vpc_id  = digitalocean_vpc.main.id
  db_name = "replay_staging"
}

module "spaces" {
  source = "../../modules/spaces"
  name   = "replay-staging"
  region = "nyc3"
}

module "firewall" {
  source     = "../../modules/firewall"
  name       = "replay-staging-fw"
  droplet_id = module.droplet.droplet_id
  ssh_allow  = var.deploy_ip_addresses
}

module "cloudflare" {
  source    = "../../modules/cloudflare"
  zone_id   = var.cloudflare_zone_id
  domain    = "staging.replaytv.co"
  server_ip = module.droplet.reserved_ip
}
```

```hcl
# infrastructure/environments/staging/outputs.tf
output "droplet_ip" {
  value = module.droplet.reserved_ip
}

output "database_url" {
  value     = module.database.connection_url
  sensitive = true
}

output "spaces_endpoint" {
  value = module.spaces.endpoint
}
```

---

## Prerequisites (one-time manual setup)

- [ ] Install OpenTofu: `brew install opentofu`
- [ ] DigitalOcean API token: Settings → API → Generate Token (read+write)
- [ ] Cloudflare API token: Profile → API Tokens → Zone:DNS:Edit
- [ ] Create state bucket manually: `doctl spaces create replay-tofu-state --region nyc3`
- [ ] Generate deploy SSH key: `ssh-keygen -t ed25519 -f ~/.ssh/kamal_deploy`
- [ ] Add domains to Cloudflare: `replaytv.co` and `rply.tv`

---

## Build order

### Phase 1 — Bootstrap

1. Install OpenTofu locally
2. Create the state bucket manually in DO Spaces
3. Create `infrastructure/` directory structure
4. Write `providers.tf` and `versions.tf` (DO + Cloudflare providers)
5. Authenticate: set `DIGITALOCEAN_TOKEN` and `CLOUDFLARE_API_TOKEN` env vars
6. Run `tofu init` to download providers

### Phase 2 — Modules

7. Write `modules/droplet/` — Droplet + reserved IP
8. Write `modules/database/` — Managed PostgreSQL + DB user
9. Write `modules/spaces/` — Spaces bucket + CORS config
10. Write `modules/firewall/` — Firewall rules (80, 443, 22)
11. Write `modules/cloudflare/` — DNS records + SSL settings

### Phase 3 — Staging environment

12. Write `environments/staging/` config using modules
13. Run `tofu plan` — review what will be created
14. Run `tofu apply` — provision staging infrastructure
15. Verify: SSH into droplet, check DNS resolves, confirm DB accessible
16. Note outputs: droplet IP, database URL, spaces endpoint
17. Feed outputs into Kamal config (`config/deploy.staging.yml`)

### Phase 4 — Production environment

18. Write `environments/production/` config (larger droplet, separate DB)
19. Add production DNS for `replaytv.co`, `*.replaytv.co`, `rply.tv`
20. Run `tofu plan` and `tofu apply`
21. Feed outputs into Kamal config (`config/deploy.yml`)

### Phase 5 — CI integration

22. Store DO and Cloudflare tokens in GitHub Actions secrets
23. Add `tofu plan` to PR workflow (shows infra changes in PR comments)
24. Infra changes applied manually via `tofu apply` (not auto-applied in CI)

### Phase 6 — Documentation

25. Write `infrastructure/README.md` — how to run, prerequisites, common operations
26. Update `docs/` with infrastructure architecture
27. Add `make infra-plan` and `make infra-apply` to Makefile

---

## Gitignore additions

```gitignore
# OpenTofu
infrastructure/**/.terraform/
infrastructure/**/*.tfstate
infrastructure/**/*.tfstate.backup
infrastructure/**/*.tfvars
!infrastructure/**/variables.tf
*.tfplan
```

Sensitive values (`terraform.tfvars` with tokens) stay out of git.
Use environment variables or a `.env` file for secrets.

---

## Common operations

```bash
# Initialize (first time or after provider changes)
cd infrastructure/environments/staging
tofu init

# Preview changes
tofu plan

# Apply changes
tofu apply

# Show current state
tofu show

# Destroy everything (careful!)
tofu destroy

# Import existing resource into state
tofu import module.droplet.digitalocean_droplet.web <droplet-id>
```

---

## What's deferred

- **Auto-apply in CI** — risky for infrastructure. Keep `tofu apply` manual until you're confident
- **Workspaces** — alternative to separate directories per environment. Adds complexity without much benefit at 2 environments
- **Monitoring resources** — provision uptime monitors via Terraform later
- **CDN / load balancer** — not needed at current scale
- **Secrets management** — use GitHub Actions secrets + Kamal env for now. Consider Vault or DO 1-Click secrets later
