variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:DNS:Edit + Zone:Zone Settings:Edit"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "cloudflare_zone_id_replaytv_dev" {
  description = "Zone ID for replaytv.dev"
  type        = string
}

variable "render_cname" {
  description = "Render staging web service CNAME (e.g., replay-staging-web.onrender.com)"
  type        = string
}
