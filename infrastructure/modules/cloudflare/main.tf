terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# ── DNS Records ─────────────────────────────────────

# Root domain → Render
resource "cloudflare_dns_record" "root" {
  zone_id = var.zone_id
  name    = var.domain
  content = var.render_cname
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# Subdomains → Render (app, admin, play, api)
resource "cloudflare_dns_record" "subdomains" {
  for_each = toset(var.subdomains)

  zone_id = var.zone_id
  name    = "${each.value}.${var.domain}"
  content = var.render_cname
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# ── Email (Resend) ──────────────────────────────────

# DKIM verification for app subdomain
resource "cloudflare_dns_record" "resend_dkim" {
  zone_id = var.zone_id
  name    = "resend._domainkey.app"
  content = "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDOz0b+0LMZ/OCBWUKSVO44MWf39MCJjFGwO6ZxtJixnNHwltiJ/57ctlaO3azwPQVpqDvCG9R5IjZ82vjYvl2vpL/TkuXutrbsAZ0MTx6+Z2hFahTmpJZ5Ljg0V3zXijpYXY2my/IDs/M3cOzCahHlnBPIMUkEyRF0vrXJ1OsE6QIDAQAB"
  type    = "TXT"
  proxied = false
  ttl     = 1
}

# SPF return path CNAMEs
resource "cloudflare_dns_record" "resend_spf_rsend" {
  zone_id = var.zone_id
  name    = "rsend.app"
  content = "rsend.forge.rmta.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "resend_spf_send" {
  zone_id = var.zone_id
  name    = "send.app"
  content = "send.forge.rmta.net"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}

# DMARC policy
resource "cloudflare_dns_record" "dmarc" {
  zone_id = var.zone_id
  name    = "_dmarc"
  content = "v=DMARC1; p=none;"
  type    = "TXT"
  proxied = false
  ttl     = 1
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
