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
    key                         = "production/terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Primary domain — replaytv.co
module "cloudflare_replaytv" {
  source = "../../modules/cloudflare"

  zone_id               = var.cloudflare_zone_id_replaytv
  domain                = "replaytv.co"
  render_cname          = var.render_cname
  subdomains            = ["app", "admin", "api"]
  cloudflare_account_id = var.cloudflare_account_id
  r2_bucket_name        = "replay-production"
  resend_dkim_key       = var.resend_dkim_key
}

# Short domain — rply.tv (QR scan URLs)
resource "cloudflare_dns_record" "rply_tv" {
  zone_id = var.cloudflare_zone_id_rply
  name    = "rply.tv"
  content = var.render_cname
  type    = "CNAME"
  proxied = true
  ttl     = 1 # Auto (required by proxied CNAME)
}

resource "cloudflare_zone_setting" "rply_ssl" {
  zone_id    = var.cloudflare_zone_id_rply
  setting_id = "ssl"
  value      = "full"
}

resource "cloudflare_zone_setting" "rply_always_https" {
  zone_id    = var.cloudflare_zone_id_rply
  setting_id = "always_use_https"
  value      = "on"
}

# ── Cloudflare Pages (React Player App) ─────────────
# One project, two custom domains (production + staging branches)

resource "cloudflare_pages_project" "player" {
  account_id        = var.cloudflare_account_id
  name              = "replay-player"
  production_branch = "main"

  build_config = {
    build_command   = "npm run build"
    destination_dir = "dist"
    root_dir        = "player-app"
    build_caching   = true
  }

  source = {
    type = "github"
    config = {
      owner                          = "omarvelous"
      repo_name                      = "replay-rails"
      production_branch              = "main"
      production_deployments_enabled = true
      preview_deployment_setting     = "all"
      preview_branch_includes        = ["*"]
      deployments_enabled            = true
      pr_comments_enabled            = true
    }
  }
}

# Production: play.replaytv.co → Pages
resource "cloudflare_pages_domain" "player_production" {
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.player.name
  name         = "play.replaytv.co"
}

resource "cloudflare_dns_record" "play_production" {
  zone_id = var.cloudflare_zone_id_replaytv
  name    = "play.replaytv.co"
  content = "replay-player-esm.pages.dev"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# Staging: play.replaytv.dev → Pages
resource "cloudflare_pages_domain" "player_staging" {
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.player.name
  name         = "play.replaytv.dev"
}

resource "cloudflare_dns_record" "play_staging" {
  zone_id = var.cloudflare_zone_id_replaytv_dev
  name    = "play.replaytv.dev"
  content = "replay-player-esm.pages.dev"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}
