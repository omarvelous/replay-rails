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
  subdomains            = ["app", "admin", "play", "api"]
  cloudflare_account_id = var.cloudflare_account_id
  r2_bucket_name        = "replay-production"
}

# Short domain — rply.tv (QR scan URLs)
resource "cloudflare_dns_record" "rply_tv" {
  zone_id = var.cloudflare_zone_id_rply
  name    = "rply.tv"
  content = var.render_cname
  type    = "CNAME"
  proxied = true
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
