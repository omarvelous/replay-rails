variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:DNS:Edit + Zone:Zone Settings:Edit"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "cloudflare_zone_id_replaytv" {
  description = "Zone ID for replaytv.co"
  type        = string
}

variable "cloudflare_zone_id_rply" {
  description = "Zone ID for rply.tv"
  type        = string
}

variable "render_cname" {
  description = "Render production web service CNAME (e.g., replay-web.onrender.com)"
  type        = string
}
