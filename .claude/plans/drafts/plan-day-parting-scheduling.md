# Plan: Day-Parting / Scheduling

## Current state
- `ScreenPlaylist` is a simple join table: `screen_id`, `playlist_id`, `active` (boolean)
- `ScreenPlaylistsController#create` destroys all existing rules and creates one with `active: true`
- Only one playlist per screen is supported
- `screens/show.html.erb` stubs "Playing: Daily · 8:00 AM – 9:00 PM" and "Timezone: America/New_York" — both hardcoded
- The `Screen.live` scope relies on `screen_playlists.where(active: true)`
- The player currently finds `screen_playlists.find_by(active: true)` to know what to play

---

## What we're building

A screen can have multiple schedule rules. Each rule assigns a playlist to a time window
and set of days. The screen plays whichever rule matches the current local time. If
nothing matches, the screen idles.

Example for one screen:
| Rule | Playlist | Days | Time |
|------|----------|------|------|
| Morning | "New Listings" | Mon–Fri | 8:00 AM – 12:00 PM |
| Afternoon | "Featured Properties" | Mon–Sun | 12:00 PM – 7:00 PM |
| Fallback | "Brand Loop" | Mon–Sun | always |

---

## Step 1 — Add `timezone` to `Site`

Time windows are meaningless without a timezone. Sites have a physical address, so
timezone belongs there — all screens in a site share it.

```ruby
# migration
add_column :sites, :timezone, :string, default: "America/New_York", null: false
```

```ruby
# app/models/site.rb
validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
```

Add a timezone select to `sites/_form.html.erb`:
```erb
<%= f.time_zone_select :timezone,
    ActiveSupport::TimeZone.all,
    { selected: site.timezone },
    class: "..." %>
```

---

## Step 2 — Extend `ScreenPlaylist` with schedule columns

The existing `active` boolean is repurposed: it now means "this rule is enabled"
(admin can pause a rule without deleting it), not "currently playing".

```ruby
# migration
remove_index :screen_playlists, %i[screen_id playlist_id]  # drop unique constraint — same playlist can appear in multiple rules

add_column :screen_playlists, :start_time,    :time     # null = no start restriction
add_column :screen_playlists, :end_time,      :time     # null = no end restriction
add_column :screen_playlists, :days_of_week,  :integer, array: true, default: []  # [] = all days; [1,2,3,4,5] = Mon–Fri
add_column :screen_playlists, :priority,      :integer, default: 0, null: false
add_column :screen_playlists, :fallback,      :boolean, default: false, null: false
add_column :screen_playlists, :label,         :string   # optional name ("Morning", "Weekend", etc.)
```

**`days_of_week` encoding:** `[0, 1, 2, 3, 4, 5, 6]` = Sun–Sat (Ruby's `Date::DAYNAMES` order).
Empty array `[]` means "all days".

---

## Step 3 — `ScreenPlaylist` model logic

```ruby
# app/models/screen_playlist.rb
class ScreenPlaylist < ApplicationRecord
  belongs_to :screen
  belongs_to :playlist

  ALL_DAYS = (0..6).to_a.freeze

  # Does this rule match right now, given a time in the screen's local timezone?
  def matches?(local_time)
    return false unless active?
    day_match?(local_time) && time_match?(local_time)
  end

  def day_match?(local_time)
    effective_days.include?(local_time.wday)
  end

  def time_match?(local_time)
    return true if start_time.nil? && end_time.nil?
    current = local_time.strftime("%H:%M")
    from    = start_time&.strftime("%H:%M") || "00:00"
    to      = end_time&.strftime("%H:%M")   || "23:59"
    current >= from && current < to
  end

  def effective_days
    days_of_week.blank? ? ALL_DAYS : days_of_week
  end
end
```

---

## Step 4 — `Screen#current_playlist`

The single resolver method that replaces all direct `screen_playlists.find_by(active: true)` calls.

```ruby
# app/models/screen.rb
def current_playlist(at: Time.current)
  local_time = at.in_time_zone(site.timezone)
  rules = screen_playlists.includes(:playlist).where(active: true).order(priority: :desc)

  # Find highest-priority matching rule
  match = rules.reject(&:fallback?).find { |r| r.matches?(local_time) }
  match ||= rules.find(&:fallback?)  # fall back to the fallback rule
  match&.playlist
end
```

Update `Screen.live` scope to use this:
```ruby
scope :live, -> {
  joins(:screen_playlists)
    .where(screen_playlists: { active: true })
    .distinct
}
# Note: Screen.live remains a "has any active rule" check for the index filter.
# The precise "playing right now" check uses current_playlist.
```

---

## Step 5 — Replace existing controller logic

`ScreenPlaylistsController` currently destroys all rules on create. Now it manages
individual rules (create, edit, delete) without touching others.

```ruby
# app/controllers/screen_playlists_controller.rb
def create
  @screen_playlist = @screen.screen_playlists.build(screen_playlist_params)
  if @screen_playlist.save
    broadcast_playlist_change
    redirect_to @screen, notice: "Schedule rule added."
  else
    render :new, status: :unprocessable_entity
  end
end

def update
  if @screen_playlist.update(screen_playlist_params)
    broadcast_playlist_change
    redirect_to @screen, notice: "Schedule rule updated."
  else
    render :edit, status: :unprocessable_entity
  end
end

def destroy
  @screen_playlist.destroy
  broadcast_playlist_change
  redirect_to @screen, notice: "Schedule rule removed."
end

private

  def screen_playlist_params
    params.require(:screen_playlist).permit(
      :playlist_id, :start_time, :end_time, :priority,
      :fallback, :active, :label, days_of_week: []
    )
  end

  def broadcast_playlist_change
    ActionCable.server.broadcast("screen_#{@screen.id}", { event: "playlist_changed" })
  end
```

Routes expand to full CRUD:
```ruby
resources :screens do
  resources :screen_playlists, only: %i[new create edit update destroy]
end
```

---

## Step 6 — Schedule UI

Replace the single "Change content" flow with a schedule rules list on `screens/show.html.erb`.

### Schedule rules list (replaces the sidebar "Schedule" stub)

```
┌─────────────────────────────────────────────────────┐
│  Schedule                          + Add rule        │
├─────────────────────────────────────────────────────┤
│  ● Morning       New Listings       Mon–Fri  8–12   │
│  ● Afternoon     Featured Props     Mon–Sun  12–19  │
│  ○ Weekend       Open Houses        Sat–Sun  10–18  │ ← disabled
│  ◆ Fallback      Brand Loop         always          │
└─────────────────────────────────────────────────────┘
```

Each row: toggle active, playlist name, label, day range, time range, edit/delete actions.

### Rule form (`screen_playlists/new.html.erb` and `edit.html.erb`)

Fields:
- **Label** — optional, e.g. "Morning", "Weekend"
- **Playlist** — select from published playlists
- **Days** — checkboxes: Mon / Tue / Wed / Thu / Fri / Sat / Sun (all checked = "every day")
- **Start time** — time input (blank = midnight)
- **End time** — time input (blank = end of day)
- **Priority** — number input (higher wins; default 0)
- **Fallback** — checkbox ("Play this when no other rule matches")
- **Active** — toggle

---

## Step 7 — Weekly schedule visualisation (optional, polish)

A read-only 7-column grid on `screens/show.html.erb` showing colored blocks
for each active rule across the week. Each playlist gets a color. Gaps show as gray.

```
       Mon  Tue  Wed  Thu  Fri  Sat  Sun
08:00  [───New Listings──────────]
12:00  [───────Featured Props────────────]
19:00
```

Rendered purely in ERB — no JS needed. Calculate pixel offsets from time values:
`top = (start_hour * 60 + start_min) / (24 * 60) * grid_height_px`

---

## Step 8 — Player: schedule-aware polling

The player currently loads `/player/play` once. With day-parting, the playlist can
change mid-day by schedule. Two mechanisms handle this:

### Admin changes (instant)
Already covered by `ScreenChannel` in the player pairing plan — broadcasts
`{ event: "playlist_changed" }` immediately when a rule is saved.

### Schedule transitions (time-based)
The player checks in every 60 seconds:

```javascript
// In player_controller.js (from pairing plan)
connect() {
  // ... subscribe to ScreenChannel
  this.poll = setInterval(() => this.checkSchedule(), 60_000)
}

async checkSchedule() {
  const token = localStorage.getItem("player_token")
  const res   = await fetch("/player/status", {
    headers: { "Authorization": `Bearer ${token}` }
  })
  const { current_playlist_id } = await res.json()
  if (current_playlist_id !== this.currentPlaylistId) {
    Turbo.visit("/player/play")
  }
}
```

```ruby
# player_controller.rb#status (update to include current playlist)
def status
  render json: {
    paired:              @player.paired?,
    current_playlist_id: @player.screen.current_playlist&.id
  }
end
```

---

## Step 9 — Solid Queue: transition jobs (optional precision upgrade)

The 60-second poll means transitions are accurate to ±60s. For precise transitions,
enqueue a job for every schedule boundary:

```ruby
# app/jobs/playlist_transition_job.rb
class PlaylistTransitionJob < ApplicationJob
  def perform(screen_id)
    screen = Screen.find(screen_id)
    ActionCable.server.broadcast("screen_#{screen_id}", { event: "playlist_changed" })
    # Re-enqueue for the next transition
    next_transition = screen.next_transition_at
    self.class.set(wait_until: next_transition).perform_later(screen_id) if next_transition
  end
end
```

`Screen#next_transition_at` calculates the earliest future boundary across all active rules.
Enqueue whenever a rule is created/updated/destroyed.

This is a meaningful complexity jump — the 60s poll covers most real-world needs.
Defer this until users actually complain about transition timing.

---

## What's deferred

- **Transition jobs (precise timing)** — 60s poll is sufficient for Phase 3
- **Holiday / date overrides** — Specific dates override the weekly schedule (e.g. "Christmas Day: closed")
- **Multi-playlist scheduling per slot** — Playing two playlists in sequence within one time window
- **Drag-and-drop schedule builder** — Visual calendar editor (complex JS)
- **Timezone auto-detection** — Infer from site address via geocoding API
