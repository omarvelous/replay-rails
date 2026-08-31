terraform {
  required_version = ">= 1.6.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket                      = "replay-tofu-state"
    key                         = "staging/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    # Endpoint set via CLI: -backend-config="endpoint=https://<account_id>.r2.cloudflarestorage.com"
    # Credentials set via AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY env vars (R2 token)
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "cloudflare_replaytv" {
  source = "../../modules/cloudflare"

  zone_id               = var.cloudflare_zone_id_replaytv
  domain                = "staging.replaytv.co"
  render_cname          = var.render_cname
  subdomains            = ["app", "admin", "play", "api"]
  cloudflare_account_id = var.cloudflare_account_id
  r2_bucket_name        = "replay-staging"
}
