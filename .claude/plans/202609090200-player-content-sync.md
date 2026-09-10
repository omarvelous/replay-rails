# Plan: Player Content Sync (Manifest Polling)

## Problem

The player only reloads when `ScreenContent` is created, updated,
or destroyed. All other content changes — listing photos, ad
images, playlist reordering, experience config, agent profiles,
template/CSS deploys — don't propagate to screens.

## Solution

A manifest endpoint that returns a JSON dependency tree of
everything the player renders. Rails ETag handles change detection.
Player polls every 30 seconds. Jbuilder templates with Russian
doll caching keep it fast.

---

## Architecture

### The Manifest IS the Version

The manifest endpoint serves a JSON document representing the
full dependency tree: every model, its `id`, `updated_at`, and
attachments. Rails auto-generates an ETag from the rendered JSON.
Player sends `If-None-Match`. If nothing changed, `304`. If any
dependency changed, different JSON, different ETag, `200`.

No custom version computation. No hash digests. The Jbuilder
template defines what matters.

### Polling

Player checks the manifest every 30 seconds with `If-None-Match`.
`304` is the common case (~200 bytes, no rendering). This catches
everything — model changes, attachment uploads, deploys. Simple,
stateless, works through every firewall and NAT.

---

## Manifest Endpoint

### Route

```ruby
# API subdomain
resources :players, param: :token, only: %i[create show] do
  scope module: "players" do
    resource :heartbeat, only: :create
    resource :manifest, only: :show
    resource :pairing_code, only: :create
  end
end
```

### Controller

```ruby
# app/controllers/api/players/manifests_controller.rb
module Api
  module Players
    class ManifestsController < Api::BaseController
      before_action :authenticate_player!

      def show
        @screen_content = @player.screen&.active_screen_content

        if @screen_content
          render :show if stale?(etag: @screen_content)
        else
          render json: { content: nil }
        end
      end
    end
  end
end
```

`stale?` computes the ETag from the rendered JSON body. Returns
`304` automatically if `If-None-Match` matches. Only renders the
full JSON when the content actually changed.

---

## Jbuilder Templates

Templates resolve partials dynamically by type — no case
statements. Adding a new contentable or adable type = add a
new partial.

### File Structure

```
app/views/api/players/manifests/
├── show.json.jbuilder
├── _playlist.json.jbuilder
├── _experience.json.jbuilder
├── _playlist_ad.json.jbuilder
├── _ad.json.jbuilder
├── _listing.json.jbuilder
├── _agent.json.jbuilder
├── _qr_code.json.jbuilder
└── ads/
    ├── _listing_ad.json.jbuilder
    ├── _agent_ad.json.jbuilder
    ├── _brand_ad.json.jbuilder
    └── _collection_ad.json.jbuilder
```

### show.json.jbuilder

```ruby
json.deploy ENV.fetch("REVISION", "dev")

json.screen_content do
  json.id @screen_content.id
  json.updated_at @screen_content.updated_at.to_i
end

json.contentable do
  json.type @screen_content.contentable_type
  json.id @screen_content.contentable_id
  json.partial! "api/players/manifests/#{@screen_content.contentable_type.underscore}",
    @screen_content.contentable_type.underscore.to_sym => @screen_content.contentable
end
```

### _playlist.json.jbuilder

```ruby
json.id playlist.id
json.updated_at playlist.updated_at.to_i
json.status playlist.status

json.playlist_ads playlist.playlist_ads.includes(ad: :adable) do |pa|
  json.partial! "api/players/manifests/playlist_ad", playlist_ad: pa
end
```

### _playlist_ad.json.jbuilder

```ruby
json.id playlist_ad.id
json.updated_at playlist_ad.updated_at.to_i
json.position playlist_ad.position
json.duration playlist_ad.duration

json.partial! "api/players/manifests/ad", ad: playlist_ad.ad
```

### _ad.json.jbuilder

```ruby
json.id ad.id
json.updated_at ad.updated_at.to_i
json.layout ad.layout
json.theme ad.theme

json.images ad.image.attached? ? [ad.image_attachment] : [] do |attachment|
  json.id attachment.id
  json.created_at attachment.created_at.to_i
end

json.adable do
  json.type ad.adable_type
  json.partial! "api/players/manifests/#{ad.adable_type.underscore}",
    ad.adable_type.demodulize.underscore.to_sym => ad.adable
end
```

### _listing.json.jbuilder

```ruby
json.id listing.id
json.updated_at listing.updated_at.to_i

json.photos listing.photos_attachments do |attachment|
  json.id attachment.id
  json.created_at attachment.created_at.to_i
end

json.floor_plans listing.floor_plans_attachments do |attachment|
  json.id attachment.id
  json.created_at attachment.created_at.to_i
end

if listing.qr_code
  json.partial! "api/players/manifests/qr_code", qr_code: listing.qr_code
end
```

### _experience.json.jbuilder

```ruby
json.id experience.id
json.updated_at experience.updated_at.to_i
json.config experience.config

json.experienceable do
  json.type experience.experienceable_type
  json.id experience.experienceable_id
  json.updated_at experience.experienceable.updated_at.to_i

  listing = experience.listing
  if listing
    json.partial! "api/players/manifests/listing", listing: listing
  end

  agent = experience.default_agent
  if agent
    json.partial! "api/players/manifests/agent", agent: agent
  end
end
```

### _agent.json.jbuilder

```ruby
json.id agent.id
json.updated_at agent.updated_at.to_i

json.photos agent.photo.attached? ? [agent.photo_attachment] : [] do |attachment|
  json.id attachment.id
  json.created_at attachment.created_at.to_i
end
```

### _qr_code.json.jbuilder

```ruby
json.id qr_code.id
json.updated_at qr_code.updated_at.to_i
```

### ads/_listing_ad.json.jbuilder

```ruby
json.id listing_ad.id
json.updated_at listing_ad.updated_at.to_i

json.partial! "api/players/manifests/listing", listing: listing_ad.listing
```

### ads/_agent_ad.json.jbuilder

```ruby
json.id agent_ad.id
json.updated_at agent_ad.updated_at.to_i

json.partial! "api/players/manifests/agent", agent: agent_ad.agent
```

### ads/_brand_ad.json.jbuilder

```ruby
json.id brand_ad.id
json.updated_at brand_ad.updated_at.to_i
```

### ads/_collection_ad.json.jbuilder

```ruby
json.id collection_ad.id
json.updated_at collection_ad.updated_at.to_i

json.collection_ads collection_ad.collection_ad_ads.includes(:ad) do |caa|
  json.id caa.id
  json.position caa.position
  json.partial! "api/players/manifests/ad", ad: caa.ad
end
```

---

## Attachments

Attachments are rendered as arrays of `active_storage_attachments`
with their `id` and `created_at`. No blob loading. Adding,
removing, or replacing an attachment changes the array →
different JSON → different ETag → `200`.

```ruby
json.photos listing.photos_attachments do |attachment|
  json.id attachment.id
  json.created_at attachment.created_at.to_i
end
```

No touch chains. No counts + max timestamps. The full attachment
list is in the manifest. Deterministic and inspectable.

---

## Deploy Detection

```ruby
json.deploy ENV.fetch("REVISION", "dev")
```

Every deploy sets a new `REVISION` (git SHA on Render). Template,
CSS, or JS changes produce a different manifest JSON even if no
model data changed. Player reloads on next poll.

---

## Russian Doll Caching (Optional)

Jbuilder supports `json.cache!` for fragment caching. Cache
model-level data, leave attachments uncached (attachment changes
don't touch parent `updated_at`):

```ruby
# _listing.json.jbuilder

# Cached — busts when listing.updated_at changes
json.cache! ["manifest/v1", listing] do
  json.id listing.id
  json.updated_at listing.updated_at.to_i
end

# Uncached — always fresh
json.photos listing.photos_attachments do |attachment|
  json.id attachment.id
  json.created_at attachment.created_at.to_i
end
```

Start without caching. Add `json.cache!` incrementally if
manifest computation becomes a bottleneck.

---

## Player JS

### Manifest Polling

```javascript
// device_playback_controller.js
connect() {
  this.manifestETag = null
  this.manifestUrl = `${this.apiHostValue}/players/${this.playerTokenValue}/manifest`

  this.manifestInterval = setInterval(() => this.checkManifest(), 30000)
}

async checkManifest() {
  try {
    const options = { credentials: "include" }
    if (this.manifestETag) {
      options.headers = { "If-None-Match": this.manifestETag }
    }

    const res = await fetch(this.manifestUrl, options)

    if (res.status === 200) {
      this.manifestETag = res.headers.get("ETag")
      window.location.reload()
    }
    // 304 = unchanged, do nothing
  } catch {
    // Network error — will retry next interval
  }
}

disconnect() {
  clearInterval(this.manifestInterval)
}
```

### ActionCable Handler (Updated)

```javascript
received: ({ event }) => {
  if (event === "content_changed" || event === "content_nudge") {
    // Check manifest instead of blind reload
    this.checkManifest()
  }
  if (event === "unpaired") this.handleUnpaired()
}
```

---

## What Triggers Detection

| User action | What changes in manifest |
|-------------|------------------------|
| Upload listing photo | New attachment in photos array |
| Remove listing photo | Attachment removed from photos array |
| Edit listing price | listing.updated_at changes |
| Change ad headline | ad.updated_at changes |
| Upload ad image | New attachment in images array |
| Reorder playlist | playlist_ad.updated_at changes |
| Add ad to playlist | New playlist_ad in array |
| Remove ad from playlist | playlist_ad removed from array |
| Toggle experience section | experience.updated_at changes |
| Update agent phone | agent.updated_at changes |
| Upload agent photo | New attachment in photos array |
| Add floor plan | New attachment in floor_plans array |
| Assign content to screen | screen_content changes entirely |
| Deploy new code | deploy value changes |

---

## Build Order (TDD)

### Phase 1: Manifest endpoint
1. RED: ManifestsController spec — returns JSON with dependency
   tree, returns 304 on unchanged ETag, returns 200 on change
2. GREEN: ManifestsController + route
3. Jbuilder templates: show, playlist, experience
4. Jbuilder partials: ad, playlist_ad, listing, agent, qr_code
5. Jbuilder adable partials: listing_ad, agent_ad, brand_ad,
   collection_ad

### Phase 2: Player JS
6. Add manifest URL value to device_playback_controller
7. Add checkManifest with ETag/If-None-Match
8. Add 30-second manifest polling interval
9. Update ActionCable handler to check manifest instead of
   blind reload
10. Pass manifest URL as data attribute from player templates

---

## Performance

**304 response:** `Rack::ETag` compares hash of rendered body
to `If-None-Match`. Still renders JSON (from cached fragments),
but returns 304 with empty body if identical.

**200 response:** Jbuilder renders JSON. First request queries
associations. Subsequent requests serve from fragment cache.
Russian doll cache keys bust when `updated_at` changes.

**Fragment caching strategy:** Cache model-level data
aggressively (`json.cache!` keyed by record). Leave attachment
arrays uncached so they're always fresh — attachment queries are
lightweight (indexed by record type + record id on
`active_storage_attachments`).

**Poll frequency:** Every 30 seconds per device. 10 devices =
20 checks per minute. Common case is 304 (cached render +
identical ETag).

---

## Resolved Questions

1. **ETag mechanism** — Option C: render every time with
   fragment caching, `Rack::ETag` auto-generates ETag from
   response body. No `stale?` pre-computation. Template is the
   single source of truth. ✓

2. **Eager loading** — Defer. Let Jbuilder trigger queries,
   rely on fragment caching to avoid repeats. First request
   is expensive, subsequent ones are cheap. Add `includes`
   later if needed. ✓

3. **Attachments** — Query `active_storage_attachments` directly
   (id + created_at). No blob loading. Adding/removing an
   attachment changes the array → different JSON → different
   ETag. Leave attachment arrays uncached so they're always
   fresh. ✓
