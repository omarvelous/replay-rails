# Plan: Experiences (Interactive Kiosk Mode)

## Problem

The current content pipeline is built for passive signage:

```
Listing → Ad → Playlist → Screen → Player
```

This works for storefront windows looping multiple listings. But the
open house use case is different — an agent wants to show one listing
on a portable screen with interactive capabilities: photo gallery,
property details, lead capture, agent info.

Forcing this through the playlist pipeline is awkward:
- Agent has to create an ad, then a playlist, then assign it
- The player renders it as a timed slideshow — no interaction
- A single-listing deep dive is not a "playlist of ads"

## Proposal

Introduce **Experiences** as a second content type that a screen can
display, alongside playlists.

```
Screen
  ├── ScreenPlaylist  → passive slideshow (existing)
  └── ScreenExperience → interactive kiosk (new)
```

An Experience is a configurable, interactive presentation of a single
listing. The player loads a kiosk-optimized web page (a variant of the
existing `/go/listings/:id` page) instead of the slideshow.

### What is an Experience?

An Experience is a lightweight model that:
- Belongs to an account (tenant-scoped)
- References a listing
- Has configurable sections (which components to show)
- Can be assigned to a screen (one active content at a time)

It is NOT:
- An ad (no layout/theme/headline — it's the listing itself)
- A playlist (no ordered items, no durations, no looping)
- A new player app (it's a web page the player loads in fullscreen)

---

## Data Model

### Experience

```ruby
class Experience < ApplicationRecord
  acts_as_tenant :account
  belongs_to :listing
  belongs_to :agent, optional: true  # override listing's default agent

  has_one :screen_experience, dependent: :destroy
  has_one :screen, through: :screen_experience

  # JSON or individual booleans for section visibility
  # Option A: jsonb config column
  # Option B: individual boolean columns
end
```

**Columns:**
- `account_id` (FK, not null)
- `listing_id` (FK, not null)
- `agent_id` (FK, nullable — defaults to listing's primary agent)
- `name` (string, optional — "123 Main St Open House")
- `config` (jsonb) — section toggles and settings

**Config structure:**
```json
{
  "sections": {
    "photos": true,
    "details": true,
    "floor_plan": true,
    "agent_card": true,
    "lead_form": true,
    "qr_handoff": true,
    "mortgage_calculator": false,
    "neighborhood": false
  },
  "idle_timeout": 30,
  "lead_form_headline": "Get the floor plan",
  "theme": "dark"
}
```

### ScreenExperience

Same pattern as `ScreenPlaylist`:

```ruby
class ScreenExperience < ApplicationRecord
  belongs_to :screen
  belongs_to :experience

  after_commit :broadcast_change

  private

  def broadcast_change
    ActionCable.server.broadcast(
      "screen_#{screen_id}",
      { event: "content_changed" }
    )
  end
end
```

**Columns:**
- `screen_id` (FK, not null)
- `experience_id` (FK, not null)
- `active` (boolean, default: true)

### Screen changes

A screen can have either an active `ScreenPlaylist` OR an active
`ScreenExperience`, never both. When one is assigned, the other is
deactivated/destroyed.

```ruby
class Screen < ApplicationRecord
  has_many :screen_playlists, dependent: :destroy
  has_many :screen_experiences, dependent: :destroy

  def active_content
    screen_experiences.find_by(active: true)&.experience ||
    screen_playlists.find_by(active: true)&.playlist
  end

  def content_type
    if screen_experiences.exists?(active: true)
      :experience
    elsif screen_playlists.exists?(active: true)
      :playlist
    else
      :none
    end
  end
end
```

---

## Player Rendering

The player controller already handles three states: unpaired, idle,
and show. Add a fourth: experience.

```ruby
# Play::PlayersController#show
def show
  # ... existing auth/pairing logic ...

  case @screen.content_type
  when :playlist
    # existing slideshow render
    @playlist_ads = ...
    render :show
  when :experience
    @experience = @screen.active_content
    render :experience
  when :none
    render :idle
  end
end
```

The `experience` template loads a kiosk-optimized page — essentially
a fullscreen, touch-friendly version of the go/listings page with
the sections configured in the experience's config.

### Key difference from slideshow

The slideshow is a Stimulus controller cycling through slides. The
experience is a single-page app with sections the visitor navigates
by touch (or that auto-cycle when idle).

**Idle behavior:** When no touch for N seconds (configurable), the
experience enters attract mode — auto-cycling through listing photos
as a screensaver. Any touch returns to the interactive view.

**Touch detection:** The page listens for touch events. If touch
is available, navigation controls appear. If not (passive screen),
it stays in attract/slideshow mode permanently. Same URL, adaptive
behavior.

---

## Sections (V1)

### 1. Photo gallery
- Full-screen photos, swipe to navigate
- Auto-slideshow when idle
- Photo counter ("3 of 12")

### 2. Property details
- Price, beds/baths/sqft, description
- Listing type badge (for sale / for rent)
- Scrollable if content is long

### 3. Agent card
- Agent photo, name, phone, email
- QR code to call/text agent directly
- "Your agent for this property"

### 4. Lead capture form
- Touch-friendly form: name, email, phone
- Configurable headline ("Get the floor plan")
- Creates a Lead with `lead_type: "open_house_rsvp"`
- Linked to listing and experience's agent
- Confirmation screen, auto-clears after 5 seconds

### 5. QR handoff
- Large QR code linking to `/go/listings/:id`
- "Continue browsing on your phone"
- Captures scan as a lead touchpoint

### 6. Floor plan viewer (if available)
- Full-screen floor plan image
- Pinch-to-zoom on touch devices
- Only shown if listing has a floor plan attached

### Deferred sections
- Mortgage calculator
- Neighborhood content
- Virtual tour embed

---

## App UI: Creating an Experience

### New experience form

```
/experiences/new?listing_id=123
```

- Pre-filled from listing
- Select agent (defaults to listing's primary agent)
- Toggle sections on/off
- Optional name
- Preview button

### Assigning to a screen

Reuse the existing "Change content" flow on screen show. Currently
it only offers playlists. Add a tab or toggle:

```
Change content for [Screen Name]
  ○ Playlist    → select from playlists
  ● Experience  → select from experiences (or create new)
```

When an experience is assigned, any active playlist is deactivated
and vice versa.

### Quick path from listing show

Add a button on listing show: "Open house mode" → creates an
experience with defaults and takes you to the screen assignment
step. One-click path for agents.

---

## Routes

```ruby
# App subdomain
resources :experiences, only: %i[index new create show edit update destroy]
resources :screens do
  resource :screen_experience, only: %i[new create destroy]
end

# Play subdomain (no changes to routes — same player show endpoint)
```

---

## Migration

```ruby
create_table :experiences do |t|
  t.timestamps
  t.references :account, null: false, foreign_key: true
  t.references :listing, null: false, foreign_key: true
  t.references :agent, foreign_key: true
  t.string :name
  t.jsonb :config, null: false, default: {}
end

create_table :screen_experiences do |t|
  t.timestamps
  t.references :screen, null: false, foreign_key: true
  t.references :experience, null: false, foreign_key: true
  t.boolean :active, null: false, default: true
end
```

---

## Build Order

### Phase A: Foundation (3-4 days)
1. Experience model + migration + factory + specs
2. ScreenExperience model + migration
3. Screen#active_content / #content_type methods
4. ExperiencesController (CRUD)
5. ScreenExperiencesController (assign/remove)
6. Policy classes

### Phase B: Player rendering (3-4 days)
7. Player controller branching (playlist vs experience)
8. Experience kiosk template — photo gallery + details
9. Touch detection + idle/attract mode
10. Agent card section
11. Lead capture form section
12. QR handoff section

### Phase C: App UI polish (2-3 days)
13. Experience form (section toggles, agent picker)
14. "Change content" flow supports both types
15. "Open house mode" quick action on listing show
16. Screen show/index reflect experience vs playlist

---

## What this does NOT include

- Neighborhood content (separate feature, deferred)
- Mortgage calculator (deferred)
- Virtual tour embeds (deferred)
- StreetEasy import (separate feature)
- Hardware recommendations or portable stand logistics
- Multi-listing interactive browse (could be a future experience type)

---

## Open Questions

1. **Should experiences be reusable?** Can the same experience be
   assigned to multiple screens, or is it 1:1? Probably 1:many
   (same open house on a lobby screen and a portable screen).

2. **Should experiences have their own URL for non-screen use?**
   e.g., agent texts a link to the experience to a client.
   Could just be the go/listings page with an `?experience=true`
   flag.

3. **Floor plan storage.** Where does the floor plan image live?
   New attachment on Listing (`has_one_attached :floor_plan`)?
   Or is it just another photo in the gallery with a tag?

4. **Lead form on-screen keyboard.** Touch screens may or may not
   have an OS-level keyboard. If not, we need a virtual keyboard
   component. Or lean on QR handoff as the primary lead capture
   and make the on-screen form secondary.
