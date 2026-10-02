# Plan: Serve Images and Assets via Cloudflare

**Created:** 2026-10-02
**Status:** Draft
**Branch:** TBD

## Problem

Images and assets currently flow through Rails:

1. **Upload path:** User uploads image → Rails → ActiveStorage →
   R2 bucket (via S3 API). This works.

2. **Serving path:** Browser requests image → Rails
   `ActiveStorage::Blobs::ProxyController` → streams from R2 →
   sends to browser. Every image request hits the Render web
   process, consumes CPU/memory, and adds latency.

The React player makes this worse — manifest includes
`rails_storage_proxy_url` which routes every image through Rails.
On a signage device cycling through ads, that's a constant stream
of image requests hitting Render.

## Current architecture

```
Browser → Render (Rails) → R2 bucket → Render → Browser
          ↑ proxy controller streams the file
```

- R2 buckets: `replay-production`, `replay-staging`
- ActiveStorage service: `cloudflare` (S3-compatible)
- Images served via `/rails/active_storage/blobs/proxy/...`
- No CDN, no caching, no public URLs

## Goal

Serve images directly from Cloudflare's edge, bypassing Rails:

```
Browser → Cloudflare CDN → R2 bucket → Browser
          ↑ cached at edge, no Rails involved
```

## Options

### Option A — R2 Public Bucket + Custom Domain

Make the R2 bucket publicly readable. Attach a custom domain
(e.g., `assets.replaytv.co`). Cloudflare automatically caches
and serves files from the edge.

```
assets.replaytv.co/uploads/abc123.jpg → R2 → cached at edge
```

**Pros:**
- Simplest setup — Cloudflare handles caching automatically
- No Workers needed
- Managed via OpenTofu (`cloudflare_r2_bucket` + custom domain)

**Cons:**
- Entire bucket is public (all uploads readable by URL)
- Need to change ActiveStorage to generate public URLs instead
  of proxy URLs
- Key/path structure of ActiveStorage blobs needs to be
  URL-friendly

### Option B — R2 with Cloudflare Workers (presigned or proxy)

Keep the bucket private. A Cloudflare Worker sits in front,
validates requests, and serves from R2. Can add caching headers.

```
assets.replaytv.co/uploads/abc123.jpg → Worker → R2 → cached
```

**Pros:**
- Bucket stays private
- Can add access control (signed URLs, referrer checks)
- Cache-Control headers set by the Worker

**Cons:**
- More complex — need to deploy and maintain a Worker
- Worker invocation cost (free tier: 100K/day, then $0.50/M)

### Option C — Cloudflare R2 Public Access with Managed Domain

R2 has built-in public access via `r2.dev` subdomain or custom
domain binding. No Worker needed. Cloudflare caches at the edge.

```
r2_bucket.public_access = true
custom_domain: assets.replaytv.co → R2 bucket
```

This is Option A but using R2's native public access feature
rather than a Worker proxy.

**Pros:**
- Zero maintenance — Cloudflare manages everything
- Free egress (R2's main advantage over S3)
- Automatic edge caching
- Managed via OpenTofu

**Cons:**
- Public bucket

## Recommendation: Option C

For a digital signage platform, all uploaded images are meant
to be displayed publicly (on screens, go pages, marketing site).
There's no sensitive content in the uploads. A public bucket
with edge caching is the right trade-off.

## Design

### R2 Public Access

Enable public access on the R2 bucket and attach a custom domain:

```hcl
# infrastructure/modules/cloudflare/main.tf
resource "cloudflare_r2_custom_domain" "assets" {
  account_id = var.cloudflare_account_id
  bucket_id  = cloudflare_r2_bucket.storage.id
  domain     = "assets.${var.domain}"
  zone_id    = var.zone_id
  enabled    = true
}
```

DNS: `assets.replaytv.co` → R2 bucket (managed by Cloudflare)

### ActiveStorage Configuration

Configure ActiveStorage to generate public URLs pointing to
the custom domain instead of proxy URLs through Rails:

```ruby
# config/storage.yml
cloudflare:
  service: S3
  endpoint: <%= Rails.application.credentials.dig(:r2, :endpoint) %>
  access_key_id: <%= Rails.application.credentials.dig(:r2, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:r2, :secret_access_key) %>
  bucket: <%= Rails.application.credentials.dig(:r2, :bucket) %>
  region: auto
  public: true
```

```ruby
# config/environments/production.rb
config.active_storage.resolve_model_to_route = :rails_storage_proxy
# Change to:
# No resolve needed — public URLs go directly to R2
```

With `public: true`, `url_for(attachment)` generates a direct
URL to the bucket. But we need it to use the custom domain, not
the raw R2 endpoint.

### Custom Domain URL Host

ActiveStorage S3 service supports a custom `url_host` option:

```ruby
# config/storage.yml (proposed)
cloudflare:
  service: S3
  endpoint: <%= Rails.application.credentials.dig(:r2, :endpoint) %>
  access_key_id: <%= Rails.application.credentials.dig(:r2, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:r2, :secret_access_key) %>
  bucket: <%= Rails.application.credentials.dig(:r2, :bucket) %>
  region: auto
  public: true
  url_host: https://assets.<%= Rails.env.production? ? "replaytv.co" : "replaytv.dev" %>
```

Now `url_for(attachment)` generates:
```
https://assets.replaytv.co/abc123...key.jpg
```

### Manifest URL Changes

The manifest Jbuilder partials currently use
`rails_storage_proxy_url(attachment)`. With public R2, they
switch to `url_for(attachment)` which generates direct URLs:

```ruby
# Before
json.url rails_storage_proxy_url(attachment)

# After
json.url url_for(attachment)
```

The React player fetches images directly from
`assets.replaytv.co` — no proxy through Rails or the Pages
Function middleware.

### Caching

Cloudflare automatically caches static assets served from R2
custom domains. Default cache behavior:

- Images (jpg, png, webp): cached at edge
- Cache-Control headers from R2 metadata respected
- Cloudflare adds `cf-cache-status: HIT` on cached responses

For explicit control, set Cache-Control on upload:

```ruby
# config/storage.yml
cloudflare:
  service: S3
  ...
  upload:
    cache_control: "public, max-age=31536000, immutable"
```

ActiveStorage blob keys are content-addressed (hash-based), so
immutable caching is safe — a changed file gets a new key.

### Impact on Existing Features

| Feature | Before | After |
|---------|--------|-------|
| Player manifest | `/rails/active_storage/proxy/...` via Render | `assets.replaytv.co/...` direct from edge |
| Go pages (listing photos) | Proxy through Rails | Direct from edge |
| App UI (listing/agent photos) | Proxy through Rails | Direct from edge |
| Ad preview in app | Proxy through Rails | Direct from edge |
| Upload | Rails → R2 (unchanged) | Rails → R2 (unchanged) |

Everything that reads images gets faster. Upload path is unchanged.

### Development

In development, ActiveStorage uses the `local` disk service.
No R2, no custom domain. Images served via Rails as usual.
No changes needed for local dev.

## Execution

```
1. Enable R2 public access + custom domain via OpenTofu
   (both staging and production)
   COMMIT

2. Update storage.yml — public: true, url_host
   COMMIT

3. Update manifest Jbuilder partials — url_for instead of
   rails_storage_proxy_url
   COMMIT

4. Update cache_control on storage config
   COMMIT

5. Test: upload an image, verify it's served from
   assets.replaytv.dev with Cloudflare cache headers
   COMMIT

6. Deploy to staging, verify player images load from edge
   COMMIT
```

## Out of scope

- Image transformations/variants at the edge (Cloudflare Images)
- Video hosting
- Signed URLs for private content
- Image optimization (WebP conversion, resizing)

## Risks

- **Public bucket** — all uploaded files are publicly accessible
  by URL. For this product (signage images, listing photos, agent
  headshots), this is acceptable. No PII in uploads.
- **Cache invalidation** — if an image is re-uploaded with the
  same ActiveStorage key, the edge cache serves stale content.
  ActiveStorage uses content-addressed keys, so this shouldn't
  happen in practice.
- **R2 public access API** — the OpenTofu Cloudflare provider
  may not support `cloudflare_r2_custom_domain` yet. Fallback:
  configure via dashboard, import into state.
