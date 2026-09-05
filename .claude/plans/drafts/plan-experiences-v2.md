# Plan: Experiences v2 (ScreenContent + Delegated Type)

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

---

## Proposal

Unify content assignment with a single `ScreenContent` model using
`delegated_type` to support both playlists and experiences.

### Before (v1 plan — two join models)

```
Screen
  ├── ScreenPlaylist  → passive slideshow
  └── ScreenExperience → interactive kiosk
```

Two join models, mutual exclusivity enforced manually, two controllers,
two sets of routes. Doesn't scale if a third content type appears.

### After (v2 — polymorphic ScreenContent)

```
Screen
  └── ScreenContent (delegated_type :contentable)
        ├── Playlist   → passive slideshow
        └── Experience → interactive kiosk
```

One join model, one controller, one set of routes. Adding a future
content type (URL, dashboard, video feed) is a one-line change.

This mirrors the existing `Ad` pattern:
```ruby
# Ad uses delegated_type for different ad formats
delegated_type :adable, types: %w[Ads::ListingAd Ads::CollectionAd ...]
```

---

## Data Model

### ScreenContent (replaces ScreenPlaylist)

```ruby
class ScreenContent < ApplicationRecord
  has_paper_trail

  belongs_to :screen
  delegated_type :contentable, types: %w[Playlist Experience]

  validates :active, uniqueness: { scope: :screen_id, conditions: -> { where(active: true) } },
            if: :active?

  after_commit :notify_player, on: %i[create update destroy]

  private

    def notify_player
      ActionCable.server.broadcast(
        "screen_#{screen_id}",
        { event: "content_changed" }
      )
    end
end
```

**Columns:**
- `screen_id` (FK, not null)
- `contentable_type` (string, not null)
- `contentable_id` (bigint, not null)
- `active` (boolean, default: true, not null)

**Key behaviors:**
- Same `after_commit` broadcast as current `ScreenPlaylist`
- `has_paper_trail` preserved from `ScreenPlaylist`
- Uniqueness constraint: only one active content per screen
- `screen_content.playlist?` / `screen_content.experience?` for type checks
- `screen_content.contentable` returns the Playlist or Experience

### Experience (new)

```ruby
class Experience < ApplicationRecord
  acts_as_tenant :account
  has_paper_trail

  belongs_to :listing
  belongs_to :agent, optional: true

  has_many :screen_contents, as: :contentable, dependent: :destroy
  has_many :screens, through: :screen_contents

  validates :listing, presence: true

  def default_agent
    agent || listing.listing_agents.first&.agent
  end
end
```

**Columns:**
- `account_id` (FK, not null)
- `listing_id` (FK, not null)
- `agent_id` (FK, nullable — override listing's default agent)
- `name` (string, optional — "123 Main St Open House")
- `config` (jsonb, default: `{}`) — section toggles and settings

**Config structure:**
```json
{
  "sections": {
    "photos": true,
    "details": true,
    "floor_plan": true,
    "agent_card": true,
    "lead_form": true,
    "qr_handoff": true
  },
  "idle_timeout": 30,
  "lead_form_headline": "Get the floor plan",
  "theme": "dark"
}
```

### Playlist changes

Playlist gains the contentable interface:

```ruby
class Playlist < ApplicationRecord
  # ... existing code ...

  has_many :screen_contents, as: :contentable, dependent: :destroy
  has_many :screens, through: :screen_contents
end
```

### Screen changes

```ruby
class Screen < ApplicationRecord
  # Replace:
  #   has_many :screen_playlists
  #   has_many :playlists, through: :screen_playlists
  # With:
  has_many :screen_contents, dependent: :destroy

  def active_screen_content
    screen_contents.find_by(active: true)
  end

  def active_content
    active_screen_content&.contentable
  end

  def content_type
    active_screen_content&.contentable_type&.downcase&.to_sym || :none
  end
end
```

---

## Migration Strategy

### Step 1: Create new tables

```ruby
class CreateExperiences < ActiveRecord::Migration[8.1]
  def change
    create_table :experiences do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.references :listing, null: false, foreign_key: true
      t.references :agent, foreign_key: true
      t.string :name
      t.jsonb :config, null: false, default: {}
    end

    create_table :screen_contents do |t|
      t.timestamps
      t.references :screen, null: false, foreign_key: true
      t.string :contentable_type, null: false
      t.bigint :contentable_id, null: false
      t.boolean :active, null: false, default: true
      t.index [:contentable_type, :contentable_id]
      t.index [:screen_id, :active], unique: true, where: "active = true"
    end
  end
end
```

### Step 2: Migrate existing data

```ruby
class MigrateScreenPlaylistsToScreenContents < ActiveRecord::Migration[8.1]
  def up
    ScreenPlaylist.find_each do |sp|
      ScreenContent.create!(
        screen_id: sp.screen_id,
        contentable_type: "Playlist",
        contentable_id: sp.playlist_id,
        active: sp.active,
        created_at: sp.created_at,
        updated_at: sp.updated_at
      )
    end
  end

  def down
    ScreenContent.where(contentable_type: "Playlist").find_each do |sc|
      ScreenPlaylist.create!(
        screen_id: sc.screen_id,
        playlist_id: sc.contentable_id,
        active: sc.active,
        created_at: sc.created_at,
        updated_at: sc.updated_at
      )
    end
  end
end
```

### Step 3: Remove old table (after code is updated)

```ruby
class DropScreenPlaylists < ActiveRecord::Migration[8.1]
  def up
    drop_table :screen_playlists
  end

  def down
    create_table :screen_playlists do |t|
      t.timestamps
      t.references :screen, null: false, foreign_key: true
      t.references :playlist, null: false, foreign_key: true
      t.boolean :active, null: false, default: true
    end
  end
end
```

---

## Controller Changes

### ScreenContentsController (replaces ScreenPlaylistsController)

```ruby
module App
  class ScreenContentsController < BaseController
    before_action :set_screen

    def new
      # Show both playlists and experiences to choose from
      authorize! ScreenContent
      @playlists = authorized_scope(Playlist.all).order(:name)
      @experiences = authorized_scope(Experience.all)
                       .includes(:listing).order(:name)
    end

    def create
      @screen.screen_contents.destroy_all
      @screen_content = @screen.screen_contents.build(
        contentable_type: params[:contentable_type],
        contentable_id: params[:contentable_id],
        active: true
      )
      authorize! @screen_content

      if @screen_content.save
        redirect_to @screen, notice: "Content updated."
      else
        redirect_to @screen, alert: "Could not assign content."
      end
    end

    def destroy
      @screen_content = @screen.screen_contents.find(params[:id])
      authorize! @screen_content
      @screen_content.destroy
      redirect_to @screen, notice: "Content removed."
    end

    private

      def set_screen
        @screen = Current.account.screens.find(params[:screen_id])
      end
  end
end
```

### ExperiencesController (new — CRUD)

```ruby
module App
  class ExperiencesController < BaseController
    before_action :set_experience, only: %i[show edit update destroy]

    def index
      @experiences = authorized_scope(Experience.all)
                       .includes(:listing, :agent)
                       .order(created_at: :desc)
    end

    def new
      @experience = Current.account.experiences.build
      @experience.listing_id = params[:listing_id] if params[:listing_id]
      authorize! @experience
    end

    def create
      @experience = Current.account.experiences.build(experience_params)
      authorize! @experience

      if @experience.save
        redirect_to @experience, notice: "Experience created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def show
      authorize! @experience
    end

    def edit
      authorize! @experience
    end

    def update
      authorize! @experience
      if @experience.update(experience_params)
        redirect_to @experience, notice: "Experience updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize! @experience
      @experience.destroy
      redirect_to experiences_path, notice: "Experience deleted."
    end

    private

      def set_experience
        @experience = Current.account.experiences.find(params[:id])
      end

      def experience_params
        params.require(:experience).permit(:listing_id, :agent_id, :name, config: {})
      end
  end
end
```

---

## Player Rendering

The player controller checks `content_type` and renders accordingly:

```ruby
# Play::PlayersController#show
def show
  # ... existing auth/pairing logic ...

  case @screen.content_type
  when :playlist
    @playlist_ads = @screen.active_content.playlist_ads
                      .includes(:ad).order(:position)
    render :show  # existing slideshow
  when :experience
    @experience = @screen.active_content
    @listing = @experience.listing
    @agent = @experience.default_agent
    render :experience  # new kiosk template
  else
    render :idle
  end
end
```

The `experience` template is a fullscreen kiosk page — a variant of
the go/listings page with:
- Touch detection (show controls if touch available)
- Idle/attract mode (auto-cycle photos after timeout)
- Sections driven by `@experience.config`

### Idle behavior

When no touch for `idle_timeout` seconds (default 30), the experience
enters attract mode — auto-cycling listing photos as a screensaver.
Any touch event returns to the full interactive view.

### Touch detection

```javascript
// experience_controller.js
const hasTouch = "ontouchstart" in window || navigator.maxTouchPoints > 0

if (hasTouch) {
  this.enableInteractiveControls()
} else {
  this.startAttractMode()  // passive photo cycle, no controls
}
```

Same URL, adaptive behavior. No mode flag needed.

---

## Routes

```ruby
# App subdomain
resources :experiences
resources :screens do
  resource :screen_content, only: %i[new create destroy]
  # Remove: resource :screen_playlist
end
```

Update all existing references from `screen_playlist` paths to
`screen_content` paths.

---

## Sections (V1)

### 1. Photo gallery
- Full-screen photos, swipe/tap to navigate
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
- Creates Lead with `lead_type: "open_house_rsvp"`
- Linked to listing and experience's agent
- Confirmation screen, auto-clears after 5 seconds
- Consider QR handoff as primary capture (avoids on-screen
  keyboard issues), with touch form as secondary

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

## App UI

### "Change content" flow (updated)

Currently `screens/show` has a "Change content" button pointing to
`new_screen_screen_playlist_path`. This becomes a unified content
picker:

```
Change content for [Screen Name]

  Playlists
    ○ Weekend Listings (4 ads · 60s loop)
    ○ Featured Properties (6 ads · 90s loop)

  Experiences
    ○ 123 Main St Open House
    ○ 456 Park Ave Showing
    [+ Create new experience]
```

### Quick path from listing show

Button on listing show: **"Open house mode"**
- Creates an Experience with defaults (all sections on)
- Redirects to screen assignment
- One-click path for agents

### Experience form

```
/experiences/new?listing_id=123
```

- Listing picker (or pre-filled from listing show)
- Agent override (defaults to listing's primary agent)
- Section toggles (checkboxes)
- Name (optional)
- Theme (dark/light)
- Preview button

---

## Refactoring Scope

### Files that change

| File | Change |
|------|--------|
| `app/models/screen_playlist.rb` | Delete (replaced by ScreenContent) |
| `app/models/screen.rb` | Replace screen_playlist associations |
| `app/models/playlist.rb` | Add `has_many :screen_contents, as: :contentable` |
| `app/controllers/app/screen_playlists_controller.rb` | Rename → ScreenContentsController |
| `app/views/app/screen_playlists/` | Rename → screen_contents/ |
| `app/views/app/screens/show.html.erb` | Update content references |
| `app/views/app/screens/index.html.erb` | Update active_playlist references |
| `config/routes.rb` | screen_playlist → screen_content |
| `app/policies/screen_playlist_policy.rb` | Rename → ScreenContentPolicy |
| `spec/requests/screen_playlists_spec.rb` | Rename + update |
| `spec/models/screen_playlist_spec.rb` | Rename + update |
| `spec/factories/screen_playlists.rb` | Rename + update |
| `app/controllers/play/players_controller.rb` | Add content_type branching |
| `app/helpers/screen_helper.rb` | Update status check for active content |

### New files

| File | Purpose |
|------|---------|
| `app/models/experience.rb` | Experience model |
| `app/models/screen_content.rb` | Unified content join model |
| `app/controllers/app/experiences_controller.rb` | CRUD |
| `app/controllers/app/screen_contents_controller.rb` | Assign/remove |
| `app/policies/experience_policy.rb` | Authorization |
| `app/policies/screen_content_policy.rb` | Authorization |
| `app/views/app/experiences/` | CRUD views |
| `app/views/app/screen_contents/` | Content picker |
| `app/views/play/players/experience.html.erb` | Kiosk template |
| `spec/models/experience_spec.rb` | Model specs |
| `spec/models/screen_content_spec.rb` | Model specs |
| `spec/requests/experiences_spec.rb` | Request specs |
| `spec/factories/experiences.rb` | Factory |
| `spec/factories/screen_contents.rb` | Factory |

---

## Build Order

### Phase A: ScreenContent migration (2-3 days)
1. Create `ScreenContent` model + migration
2. Migrate data from `screen_playlists` → `screen_contents`
3. Update Screen model associations
4. Update Playlist model (add contentable)
5. Rename controller, policy, views, routes
6. Update player controller for new model
7. Update all specs
8. Drop `screen_playlists` table
9. Verify everything works identically to before

### Phase B: Experience model + CRUD (2-3 days)
10. Experience model + migration + factory + specs
11. ExperiencesController (CRUD)
12. ExperiencePolicy
13. Experience form views (section toggles, agent picker)
14. ScreenContentsController updated to offer experiences
15. "Open house mode" button on listing show

### Phase C: Kiosk player rendering (3-4 days)
16. Player controller branching (playlist vs experience)
17. Experience kiosk template — photo gallery + details
18. Touch detection Stimulus controller
19. Idle/attract mode (auto-cycle photos)
20. Agent card section
21. Lead capture form section
22. QR handoff section

### Phase D: Polish (1-2 days)
23. Screen show/index reflect content type
24. Experience preview
25. Mobile UX for experience creation

---

## Open Questions

1. **Should experiences be reusable across screens?** Probably yes —
   same open house on a lobby screen and a portable screen. The
   `has_many :screen_contents` already supports this.

2. **Experience URL for non-screen use?** Agent texts a link to the
   kiosk view to a client. Could be `/go/experiences/:id` or
   `/go/listings/:id?kiosk=true`.

3. **Floor plan storage.** New attachment on Listing
   (`has_one_attached :floor_plan`)? Or tagged photo in gallery?

4. **On-screen keyboard.** Touch screens may not have OS keyboards.
   QR handoff as primary lead capture avoids this. On-screen form
   is secondary / nice-to-have.

5. **Naming.** "Experience" is the internal model name. What do
   agents see in the UI? "Open House Mode"? "Interactive Display"?
   "Kiosk"? The right label matters for adoption.
