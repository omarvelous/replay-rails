# Plan: Smart Player Push Updates

## Problem

The player only reloads when `ScreenContent` is created, updated,
or destroyed. All other content changes — listing photos, ad
images, playlist reordering, experience config, agent profiles —
require manual reload or content swap to appear on screen.

This is a bad UX: a user uploads a photo to a listing, expects
it to appear on the kiosk, but nothing happens.

## Current State

Only broadcast: `ScreenContent` after_commit → `content_changed`

The player JS listens on `ScreenChannel` for `content_changed`
and calls `window.location.reload()`.

## What Should Trigger Reloads

### Playlist content path
```
Ad updated (image, headline, layout, theme)
  → find screens showing playlists containing this ad
  → broadcast content_changed to each

PlaylistAd added/removed/reordered
  → find screens showing this playlist
  → broadcast content_changed to each

Listing updated (photos, price, address, description)
  → find ads built from this listing
  → find screens showing playlists containing those ads
  → broadcast content_changed to each
```

### Experience content path
```
Experience updated (config changed)
  → find screens showing this experience
  → broadcast content_changed to each

Listing updated (photos, price, address, description)
  → find experiences for this listing
  → find screens showing those experiences
  → broadcast content_changed to each

Agent updated (photo, name, phone, email)
  → find experiences using this agent
  → find screens showing those experiences
  → broadcast content_changed to each
```

### Both paths
```
Listing photos attached/removed
  → triggers listing updated path (both ad and experience)
```

## Approach

### Option A: Callbacks on each model

Add `after_commit` callbacks on every model in the chain that
walks up to ScreenContent and broadcasts. Simple but scattered —
6+ models each with broadcast logic.

### Option B: Centralized notifier concern

A `NotifiesScreens` concern included in relevant models. Each
model declares which association path leads to screens:

```ruby
class Ad < ApplicationRecord
  include NotifiesScreens
  notifies_screens through: -> { screen_contents_via_playlists }
end
```

The concern handles the broadcast. One pattern, multiple models.

### Option C: Single broadcast method on Screen

Models call `Screen.notify_content_changed(screen_ids)` which
broadcasts to each screen. Models are responsible for finding
affected screen IDs, but the broadcast logic is in one place.

```ruby
# In any model after_commit
Screen.notify_content_changed(affected_screen_ids)
```

### Option D: PaperTrail-based detection

PaperTrail already tracks changes on most models. A background
job or callback could check if a changed record is in the
dependency chain of any active screen content and broadcast.
Decoupled but delayed.

### Recommendation

**Option C** — simplest, most explicit. Each model knows its
relationship to screens and calls `Screen.notify_content_changed`.
No magic, no concern inheritance, one broadcast method.

---

## Models That Need Callbacks

| Model | When | How to find affected screens |
|-------|------|----------------------------|
| `Ad` | after_commit on update | `screen_contents.where(contentable: playlists).pluck(:screen_id)` via playlist_ads |
| `PlaylistAd` | after_commit on create/update/destroy | `playlist.screen_contents.pluck(:screen_id)` |
| `Listing` | after_commit on update | Via ads (playlist path) + via experiences (experience path) |
| `Experience` | after_commit on update | `screen_contents.pluck(:screen_id)` |
| `Experiences::ListingExperience` | after_commit on update | `experience.screen_contents.pluck(:screen_id)` |
| `Agent` | after_commit on update | Via listing_experiences where agent_id = self.id |

### ActiveStorage attachments

Photo uploads on Listing and Agent don't trigger `after_commit`
on the parent model. Options:
- Use `after_commit` on the attachment record (complex)
- Touch the parent: `has_many_attached :photos, dependent: :purge_later` with `touch: true` on the blob? Not built-in.
- After the controller action that handles upload, explicitly call `Screen.notify_content_changed`

**Simplest for attachments:** In the controller, after successful
attachment upload, call the notification. This is explicit and
avoids hooking into ActiveStorage internals.

---

## Screen.notify_content_changed

```ruby
class Screen < ApplicationRecord
  def self.notify_content_changed(screen_ids)
    Array(screen_ids).uniq.each do |screen_id|
      ActionCable.server.broadcast(
        "screen_#{screen_id}",
        { event: "content_changed" }
      )
    end
  end
end
```

### Helper methods for finding affected screens

```ruby
class Ad < ApplicationRecord
  def affected_screen_ids
    Playlist.joins(:playlist_ads)
      .where(playlist_ads: { ad_id: id })
      .joins(:screen_contents)
      .where(screen_contents: { active: true })
      .pluck("screen_contents.screen_id")
  end
end

class Listing < ApplicationRecord
  def affected_screen_ids
    # Via ads (playlist path)
    ad_ids = ads.pluck(:id)
    playlist_screens = ScreenContent.where(
      contentable_type: "Playlist",
      active: true
    ).joins("INNER JOIN playlist_ads ON playlist_ads.playlist_id = screen_contents.contentable_id")
     .where(playlist_ads: { ad_id: ad_ids })
     .pluck(:screen_id)

    # Via experiences
    experience_ids = Experiences::ListingExperience
      .where(listing_id: id)
      .joins(:experience)
      .pluck("experiences.id")
    experience_screens = ScreenContent.where(
      contentable_type: "Experience",
      contentable_id: experience_ids,
      active: true
    ).pluck(:screen_id)

    (playlist_screens + experience_screens).uniq
  end
end
```

---

## Debouncing

Multiple rapid changes (uploading 5 photos) shouldn't trigger
5 reloads. Options:

- **Client-side debounce:** Player JS debounces reload —
  multiple `content_changed` events within 2 seconds only
  trigger one reload.
- **Server-side debounce:** Use Solid Queue to schedule a
  delayed broadcast. If another broadcast is scheduled for
  the same screen within N seconds, skip it.

**Recommendation:** Client-side debounce — simpler, no server
state. The player already reloads on `content_changed`. Add a
2-second debounce:

```javascript
received: ({ event }) => {
  if (event === "content_changed") {
    clearTimeout(this.reloadTimeout)
    this.reloadTimeout = setTimeout(() => window.location.reload(), 2000)
  }
}
```

---

## Deployment Reloads

CSS/JS changes from deployments don't trigger ActionCable events.
Options:

- **Asset fingerprinting:** Turbo already handles this for app
  pages via importmap changes. Player pages aren't Turbo-driven.
- **Version endpoint:** Player polls a `/api/version` endpoint.
  If the version changes (deploy), reload.
- **ActionCable broadcast on deploy:** A post-deploy script
  broadcasts to all screens.

**Defer for now.** Deployments are infrequent and a manual
reload is acceptable. The version endpoint is a future nice-to-have.

---

## Build Order

### Phase 1: Foundation
1. Add `Screen.notify_content_changed` class method
2. Add client-side debounce to player JS

### Phase 2: Model callbacks
3. Ad after_commit → notify affected screens
4. PlaylistAd after_commit → notify affected screens
5. Experience after_commit → notify affected screens
6. Listing after_commit → notify affected screens
7. Agent after_commit → notify affected screens

### Phase 3: Attachment handling
8. Listings controller → notify after photo upload
9. Agents controller → notify after photo upload
10. Listings controller → notify after floor_plan upload

### Phase 4: Testing
11. Specs for Screen.notify_content_changed
12. Specs for affected_screen_ids on each model

---

## Open Questions

1. **Listing experience agent updates** — if the agent on a
   ListingExperience changes, should that trigger a reload?
   Yes — the kiosk shows the agent card.

2. **Brand/collection ads** — BrandAd and CollectionAd updates
   should also trigger reloads via the same Ad path.

3. **Playlist status changes** — if a playlist goes from
   published to draft, should the screen go idle? Currently
   ScreenContent doesn't check playlist status.
