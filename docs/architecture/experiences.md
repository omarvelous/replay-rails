# Experiences

Experiences are interactive kiosk presentations displayed on screens. While playlists are passive slideshows of ads, experiences let visitors browse listing details, swipe through photos, view floor plans, and scan QR codes — all on a touch-enabled screen.

## Models

### ScreenContent (delegated type)

`ScreenContent` is the join between a Screen and its content. It uses `delegated_type :contentable` with two variants:

| Type | Class | Description |
|------|-------|-------------|
| Playlist | `Playlist` | Passive ad slideshow |
| Experience | `Experience` | Interactive kiosk |

A screen has one active content assignment at a time. `after_commit` broadcasts `content_changed` to notify the player.

### Experience

```ruby
delegated_type :experienceable, types: %w[Experiences::ListingExperience]
has_many :screen_contents, as: :contentable
```

- `name` — display name for the experience
- `config` — jsonb hash controlling which sections are enabled (photos, details, agent_card, qr_handoff, floor_plans) and idle timeout

### Experiences::ListingExperience

```ruby
belongs_to :listing
belongs_to :agent, optional: true
```

The primary experienceable type. Presents a single listing with:
- Photo gallery (swipe navigation)
- Property details (price, address, specs, description)
- Agent card (from assigned agent or listing's primary agent)
- QR handoff (scan to view on phone)
- Floor plans (overlay on tap)

`default_agent` resolves: explicitly assigned agent → listing's primary agent → nil.

## Player rendering

The player controller branches on `screen.content_type`:

- `"Playlist"` → renders slideshow template with `device_playback_controller.js`
- `"Experience"` → renders kiosk template with `experience_controller.js` + `device_playback_controller.js`

### Experience Stimulus controller

`experience_controller.js` handles:
- **Photo gallery** — swipe/tap navigation with slide counter
- **Idle detection** — returns to attract mode after configurable timeout
- **Floor plan overlay** — tap to show/hide
- **Touch mode** — shows navigation controls when touch is detected
- **Session tracking** — `ahoy.reset()` on idle break for clean kiosk sessions
- **Interaction events** — fires `interaction.started`, `interaction.ended`, `interaction.navigated`, `interaction.opened`, `interaction.closed` via the analytics wrapper

## Manifest

The player manifest includes experience data when the screen's content is an experience:

```json
{
  "content_type": "Experience",
  "experience": {
    "id": 1,
    "config": { "sections": { ... } },
    "experienceable": {
      "listing": { "id": 1, "photos": [...], "floor_plans": [...] },
      "agent": { "id": 1, "photos": [...] }
    }
  }
}
```

Dynamic partials resolve by experienceable type: `experiences/_listing_experience.json.jbuilder`.
