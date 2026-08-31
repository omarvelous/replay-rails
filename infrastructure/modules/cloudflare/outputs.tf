output "r2_bucket_name" {
  value = cloudflare_r2_bucket.storage.name
}

output "dns_records" {
  value = {
    root       = cloudflare_dns_record.root.name
    subdomains = [for r in cloudflare_dns_record.subdomains : r.name]
  }
}
