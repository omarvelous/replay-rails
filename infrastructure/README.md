# Infrastructure

OpenTofu configuration for RePlay's Cloudflare resources (DNS, SSL, R2 storage).

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) installed (`brew install opentofu`)
- Cloudflare API token with Zone:DNS:Edit + Zone:Zone Settings:Edit permissions
- Cloudflare R2 API token (Access Key ID + Secret Access Key)
- State bucket `replay-tofu-state` created in R2

## Environment variables

Set these before running `tofu` commands:

```bash
# From .env at repo root (not committed)
export CLOUDFLARE_API_TOKEN=<your-api-token>
export CLOUDFLARE_ACCOUNT_ID=<your-account-id>

# R2 credentials for state backend
export AWS_ACCESS_KEY_ID=<r2-access-key-id>
export AWS_SECRET_ACCESS_KEY=<r2-secret-access-key>
```

## Usage

### Initialize (first time)

```bash
cd infrastructure/environments/staging

tofu init \
  -backend-config="endpoint=https://${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com" \
  -backend-config="access_key=${AWS_ACCESS_KEY_ID}" \
  -backend-config="secret_key=${AWS_SECRET_ACCESS_KEY}"
```

### Plan (preview changes)

```bash
tofu plan \
  -var="cloudflare_api_token=${CLOUDFLARE_API_TOKEN}" \
  -var="cloudflare_account_id=${CLOUDFLARE_ACCOUNT_ID}" \
  -var="cloudflare_zone_id_replaytv=<zone-id>" \
  -var="render_cname=replay-staging-web.onrender.com"
```

### Apply (provision resources)

```bash
tofu apply \
  -var="cloudflare_api_token=${CLOUDFLARE_API_TOKEN}" \
  -var="cloudflare_account_id=${CLOUDFLARE_ACCOUNT_ID}" \
  -var="cloudflare_zone_id_replaytv=<zone-id>" \
  -var="render_cname=replay-staging-web.onrender.com"
```

### Using a tfvars file (recommended)

Create `infrastructure/environments/staging/terraform.tfvars` (gitignored):

```hcl
cloudflare_api_token        = "your-token"
cloudflare_account_id       = "your-account-id"
cloudflare_zone_id_replaytv = "your-zone-id"
render_cname                = "replay-staging-web.onrender.com"
```

Then simply:

```bash
tofu plan
tofu apply
```

## Structure

```
infrastructure/
├── modules/
│   └── cloudflare/         # Reusable: DNS records, SSL, R2 bucket
├── environments/
│   ├── staging/            # Staging config (staging.replaytv.co)
│   └── production/         # Production config (replaytv.co + rply.tv)
├── versions.tf             # Provider version constraints
└── README.md
```

## What this manages

| Resource | Description |
|----------|-------------|
| DNS CNAME records | Root + app/admin/play/api subdomains → Render |
| SSL mode | Full (Strict), Always HTTPS, min TLS 1.2 |
| R2 bucket | File storage for ActiveStorage uploads |
| rply.tv DNS (prod) | Short domain for QR scan URLs |

## What this does NOT manage

- Render services (managed via `render.yaml` in repo root)
- Render databases (managed via `render.yaml`)
- R2 API tokens (created manually in Cloudflare dashboard)
- State bucket (created manually — bootstrap chicken-and-egg)
