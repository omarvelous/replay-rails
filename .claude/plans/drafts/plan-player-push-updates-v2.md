# Plan: Player Content Sync (Manifest + Nudge)

## Problem

The player only reloads when `ScreenContent` is created, updated,
or destroyed via ActionCable. All other content changes — listing
photos, ad images, playlist reordering, experience config, agent
profiles, template/CSS deploys — don't propagate to screens.

## Industry Pattern

Every production signage/IoT platform uses **manifest polling
with conditional GET + push nudge**:

1. Player polls a manifest endpoint on an interval
2. Server returns `304 Not Modified` if nothing changed (ETag)
3. If changed, server returns `200` with new content version
4. Push channel (ActionCable) sends a "nudge" for instant updates
5. If push channel drops, polling still catches changes

This gives instant updates when connected and graceful degradation
when not.

---

## Architecture

### Two Concerns, Two Endpoints

**Heartbeat (write):** `POST /api/players/:token/heartbeat`
- "I'm alive" — updates `last_heartbeat_at`, `ip_address`
- Lightweight, fire-and-forget
- Unchanged from today

**Manifest (read):** `GET /api/players/:token/manifest`
- "What should I show?" — returns content version and metadata
- Supports `ETag` / `If-None-Match` for conditional GET
- `304` when unchanged (common case), `200` when content differs
- Cacheable, stateless, CDN-friendly

### Player Flow

```
1. Player loads GET /players/:token (HTML)
   → Renders content
   → Stores content_version from response

2. Every 30s:
   POST /heartbeat (fire-and-forget)
   GET /manifest (with If-None-Match: current_version)
     → 304: do nothing
     → 200: content changed → reload page

3. ActionCable receives "content_nudge":
   → Immediately GET /manifest (skip waiting for next poll)
   → 304: false alarm (already current)
   → 200: reload
```

### Why Not Just ActionCable?

- WebSocket connections drop silently
- Solid Cable has polling intervals (not truly instant)
- Devices go through NAT, firewalls, proxies
- The manifest poll catches anything ActionCable misses
- 304 responses are ~200 bytes — negligible bandwidth

### Why Not Just Polling?

- 30-second latency for changes is noticeable
- ActionCable nudge makes it feel instant
- Both together = resilient + responsive

---

## Content Version (Deterministic)

The version is a digest of everything the player renders. Same
content state always produces the same hash.

### Components

```ruby
class Screen
  def content_version
    parts = [deploy_version]
    parts += contentable_version_parts
    Digest::SHA256.hexdigest(parts.compact.join("/"))[0..15]
  end

  private

  def deploy_version
    # Changes on every deploy — captures template/CSS/JS changes
    ENV.fetch("REVISION") { Rails.application.importmap.digest }
  end

  def contentable_version_parts
    case content_type
    when :playlist then playlist_version_parts
    when :experience then experience_version_parts
    else []
    end
  end

  def playlist_version_parts
    playlist = active_content
    parts = [playlist.cache_key_with_version]

    playlist.playlist_ads.includes(ad: :adable).each do |pa|
      parts << pa.cache_key_with_version
      parts << pa.ad.cache_key_with_version
      parts << pa.ad.image.blob.cache_key_with_version if pa.ad.image.attached?

      adable = pa.ad.adable
      parts << adable.cache_key_with_version
      if adable.respond_to?(:listing)
        listing = adable.listing
        parts << listing.cache_key_with_version
        parts << listing.photos.count
        parts << listing.photos.blobs.maximum(:created_at)&.to_i
      end
    end

    parts
  end

  def experience_version_parts
    experience = active_content
    parts = [experience.cache_key_with_version]
    parts << experience.experienceable.cache_key_with_version

    listing = experience.listing
    if listing
      parts << listing.cache_key_with_version
      parts << listing.photos.count
      parts << listing.photos.blobs.maximum(:created_at)&.to_i
      parts << listing.floor_plans.count
      parts << listing.floor_plans.blobs.maximum(:created_at)&.to_i
    end

    agent = experience.default_agent
    if agent
      parts << agent.cache_key_with_version
      parts << agent.photo.blob&.cache_key_with_version if agent.photo.attached?
    end

    parts
  end
end
```

### What This Captures

| Change | How it's captured |
|--------|------------------|
| Deploy (templates, CSS, JS) | `ENV["REVISION"]` changes |
| Playlist reordered | PlaylistAd `cache_key_with_version` (updated_at) |
| Ad headline/layout/theme changed | Ad `cache_key_with_version` |
| Ad image uploaded | `ad.image.blob.cache_key_with_version` |
| Listing price/address changed | Listing `cache_key_with_version` |
| Listing photo added/removed | `photos.count` + `photos.blobs.maximum(:created_at)` |
| Experience config toggled | Experience `cache_key_with_version` |
| Agent name/phone changed | Agent `cache_key_with_version` |
| Agent photo uploaded | `agent.photo.blob.cache_key_with_version` |
| Floor plan added | `floor_plans.count` + `maximum(:created_at)` |

### ActiveStorage Gap

Attaching a photo doesn't touch the parent model's `updated_at`.
Solved by including attachment count + latest blob timestamp in
the digest. No `touch: true` chains needed.

---

## Manifest Endpoint

```ruby
# app/controllers/api/players/manifests_controller.rb
module Api
  module Players
    class ManifestsController < Api::BaseController
      before_action :authenticate_player!

      def show
        screen = @player.screen
        return render json: { content: nil }, status: :ok unless screen

        version = screen.content_version

        if stale?(etag: version)
          render json: {
            content_version: version,
            content_type: screen.content_type,
            content_id: screen.active_content&.id
          }
        end
      end
    end
  end
end
```

### Route

```ruby
# In API subdomain
resources :players, param: :token, only: %i[create show] do
  scope module: "players" do
    resource :heartbeat, only: :create
    resource :manifest, only: :show
    resource :pairing_code, only: :create
  end
end
```

### Response Examples

**304 Not Modified** (common case):
```
HTTP/1.1 304 Not Modified
ETag: "a3f8c2b1e9d04f67"
```

**200 OK** (content changed):
```json
{
  "content_version": "a3f8c2b1e9d04f67",
  "content_type": "playlist",
  "content_id": 5
}
```

**200 OK** (no content assigned):
```json
{
  "content": null
}
```

---

## ActionCable Nudge

Keep the existing `ScreenChannel` and `content_changed` broadcast.
But now it's a "nudge" — it tells the player to check the manifest
immediately, not to reload blindly.

### What Triggers a Nudge

Replace the single `ScreenContent` after_commit with nudges from
multiple models. Use `Screen.nudge(screen_ids)`:

```ruby
class Screen
  def self.nudge(screen_ids)
    Array(screen_ids).uniq.each do |id|
      ActionCable.server.broadcast("screen_#{id}", { event: "content_nudge" })
    end
  end
end
```

### Models That Nudge

Each model has a simple `after_commit` that finds affected screens
and nudges:

```ruby
class Ad < ApplicationRecord
  after_commit :nudge_screens, on: [:update]

  private

  def nudge_screens
    screen_ids = playlists
      .joins(:screen_contents)
      .where(screen_contents: { active: true })
      .pluck("screen_contents.screen_id")
    Screen.nudge(screen_ids) if screen_ids.any?
  end
end
```

| Model | After commit | Screen resolution |
|-------|-------------|-------------------|
| `ScreenContent` | create/update/destroy | Direct: `screen_id` |
| `Ad` | update | Via playlist_ads → playlists → screen_contents |
| `PlaylistAd` | create/update/destroy | Via playlist → screen_contents |
| `Experience` | update | Via screen_contents |
| `Listing` | update | Via ads (playlist path) + via listing_experiences (experience path) |
| `Agent` | update | Via listing_experiences → experiences → screen_contents |

### Attachment Nudges

ActiveStorage changes don't fire model `after_commit`. Handle
in controllers after successful attachment:

```ruby
# In ListingsController#update (after photo upload)
Screen.nudge(@listing.affected_screen_ids) if @listing.photos.attached?
```

---

## Player JS Changes

### Manifest polling

```javascript
// device_playback_controller.js

connect() {
  // ... existing setup ...
  this.contentVersion = this.element.dataset.contentVersion
  this.manifestInterval = setInterval(() => this.checkManifest(), 30000)
}

async checkManifest() {
  try {
    const res = await fetch(
      `${this.apiHostValue}/players/${this.playerTokenValue}/manifest`,
      {
        credentials: "include",
        headers: this.contentVersion
          ? { "If-None-Match": `"${this.contentVersion}"` }
          : {}
      }
    )

    if (res.status === 200) {
      // Content changed — reload
      window.location.reload()
    }
    // 304 = unchanged, do nothing
  } catch {
    // Network error — will retry next interval
  }
}
```

### ActionCable nudge handler

```javascript
received: ({ event }) => {
  if (event === "content_nudge") {
    // Don't reload blindly — check manifest first
    this.checkManifest()
  }
  if (event === "content_changed") {
    // Legacy support during transition
    this.checkManifest()
  }
  if (event === "unpaired") this.handleUnpaired()
}
```

### Debouncing

Multiple rapid nudges (5 photos uploaded) trigger 5 nudge events.
Debounce the manifest check:

```javascript
received: ({ event }) => {
  if (event === "content_nudge" || event === "content_changed") {
    clearTimeout(this.nudgeTimeout)
    this.nudgeTimeout = setTimeout(() => this.checkManifest(), 2000)
  }
}
```

---

## Content Version in Player Template

Pass the version as a data attribute so the player knows what
it loaded with:

```erb
data-device-playback-content-version-value="<%= @screen&.content_version %>"
```

---

## Performance

### Manifest computation cost

`content_version` queries related models. For a playlist with
5 ads:
- 1 playlist load
- 5 playlist_ads with ads + adables (eager loaded)
- ~2 listing queries for photos count/max
- Digest computation

Estimated: ~5ms. At 10 devices × 1 check per 30s = 20 checks
per minute. Negligible.

### Caching the version

For higher scale, cache the computed version on ScreenContent:

```ruby
class ScreenContent
  def cached_content_version
    Rails.cache.fetch("screen_content/#{id}/version", expires_in: 30.seconds) do
      screen.content_version
    end
  end
end
```

Cache is busted naturally by time expiry (30s matches poll
interval). Nudges don't need to bust the cache — the next
manifest check recomputes.

---

## Migration Path

### Phase 1: Manifest endpoint + version
1. Add `content_version` method to Screen
2. Create ManifestsController with ETag support
3. Add route
4. Pass content_version to player templates

### Phase 2: Player JS
5. Add manifest polling to device_playback_controller.js
6. Change ActionCable handler from reload to nudge → check
7. Add debouncing

### Phase 3: Model nudges
8. Add `Screen.nudge` class method
9. Add after_commit nudges to Ad, PlaylistAd, Experience,
   Listing, Agent
10. Add controller-level nudges for attachment uploads

### Phase 4: Cleanup
11. Remove blind `window.location.reload()` on content_changed
12. Update ScreenContent broadcast to use `content_nudge`

---

## What This Does NOT Cover

- Full content payload in manifest (just version for now)
- Offline caching / Service Worker on player
- Content pre-fetching (download assets before switching)
- Deploy-triggered reload (use `ENV["REVISION"]` in version)
- MQTT or SSE (ActionCable + polling is sufficient for now)

---

## Open Questions

1. **Manifest computation on every heartbeat** — 5ms per check
   is fine at small scale. At 100+ devices, consider caching
   the version on ScreenContent and busting on nudge.

2. **Deploy detection** — `ENV["REVISION"]` works if Render sets
   it. Need to verify. Fallback: importmap digest.

3. **Nudge from attachment controllers** — listings controller
   permits photo uploads. Need to identify all controller
   actions that modify attachments and add nudges.

4. **Transition period** — during rollout, support both
   `content_changed` (legacy reload) and `content_nudge`
   (new manifest check) events.
