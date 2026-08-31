variable "zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}

variable "domain" {
  description = "Domain name (e.g., staging.replaytv.co or replaytv.co)"
  type        = string
}

variable "render_cname" {
  description = "Render service CNAME target (e.g., replay-web.onrender.com)"
  type        = string
}

variable "subdomains" {
  description = "List of subdomains to create CNAME records for"
  type        = list(string)
  default     = ["app", "admin", "play", "api"]
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "r2_bucket_name" {
  description = "Name for the R2 storage bucket"
  type        = string
}
