# ── DNS Records ─────────────────────────────────────

# Root domain → Render
resource "cloudflare_dns_record" "root" {
  zone_id = var.zone_id
  name    = var.domain
  content = var.render_cname
  type    = "CNAME"
  proxied = true
}

# Subdomains → Render (app, admin, play, api)
resource "cloudflare_dns_record" "subdomains" {
  for_each = toset(var.subdomains)

  zone_id = var.zone_id
  name    = "${each.value}.${var.domain}"
  content = var.render_cname
  type    = "CNAME"
  proxied = true
}

# ── SSL / Security Settings ─────────────────────────

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.zone_id
  setting_id = "ssl"
  value      = "full"
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

# ── R2 Storage ──────────────────────────────────────

resource "cloudflare_r2_bucket" "storage" {
  account_id = var.cloudflare_account_id
  name       = var.r2_bucket_name
  location   = "ENAM"
}
