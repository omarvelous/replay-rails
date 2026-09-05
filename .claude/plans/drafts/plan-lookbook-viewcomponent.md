# Plan: Add Lookbook (Component Preview Gallery) to replay-rails

## Context

The ad system has 6 layout partials × 4 ad types × 3 themes × multiple badge variants — dozens of visual states that currently require navigating through the full app with real data to see. Lookbook gives us a browsable gallery (like Storybook) to preview these partials in isolation, accelerating design iteration and catching visual regressions.

This plan adds Lookbook on top of **existing ERB partials** — no refactoring required. An extension section covers selectively promoting ad partials to ViewComponents where the encapsulation justifies the effort.

---

## Phase 1: Lookbook with Partial Previews

### Step 1 — Add gems

**File:** [Gemfile](Gemfile)

Add to the `group :development` block:

```ruby
gem "view_component"   # Required runtime dep for Lookbook 2.x
gem "lookbook", ">= 2.3"
```

Then `make build` to rebuild the Docker image.

### Step 2 — Mount the engine

**File:** [config/routes.rb](config/routes.rb) (line 2, next to LetterOpenerWeb)

```ruby
mount Lookbook::Engine, at: "/lookbook" if Rails.env.development?
```

Accessible at `http://replay.localhost:3000/lookbook`.

### Step 3 — Lookbook initializer

**New file:** `config/initializers/lookbook.rb`

```ruby
if defined?(Lookbook)
  Rails.application.configure do
    config.lookbook.preview_paths = [Rails.root.join("spec/components/previews")]
    config.lookbook.preview_layout = "lookbook_preview"
    config.lookbook.project_name = "RePlay"
    config.lookbook.ui_theme = "indigo"
  end
end
```

Uses `spec/` (not `test/`) to match the project's RSpec convention.

### Step 4 — Preview layout (loads Tailwind + ad canvas CSS)

**New file:** `app/views/layouts/lookbook_preview.html.erb`

Includes `stylesheet_link_tag "tailwind"` and `"application"` so `.ad-canvas` container queries, theme variables, and DaisyUI classes all work inside Lookbook's iframe.

### Step 5 — Preview controller (skip auth + tenant)

**New file:** `app/controllers/lookbook_preview_controller.rb`

Inherits from `ApplicationController`, skips `authenticate` and `set_current_tenant` so previews render without login. Sets `default_url_options` for route helpers.

### Step 6 — Preview data helpers (no database)

**New file:** `spec/components/previews/preview_helpers.rb`

Module with `stub_ad`, `stub_listing`, `stub_agent` methods that return OpenStruct objects duck-typing the interfaces the partials expect (`ad.adable`, `ad.theme`, `ad.image.attached?`, `listing.price`, etc.). No FactoryBot, no database — previews are fast and stateless.

### Step 7 — Ad layout preview classes

Each preview class inherits `ViewComponent::Preview` and uses `render_with_template` to render the existing partials. One template file per scenario (each is a single `<%= render %>` line).

**Directory structure:**

```
spec/components/previews/
├── preview_helpers.rb
└── ads/
    ├── listing_ad_preview.rb          # 7 scenarios (4 layouts × badges)
    │   └── listing_ad_preview/
    │       ├── hero_just_listed.html.erb
    │       ├── hero_open_house.html.erb
    │       ├── hero_just_sold.html.erb
    │       ├── hero_price_reduction.html.erb
    │       ├── split.html.erb
    │       ├── minimal.html.erb
    │       └── stat_grid.html.erb
    ├── brand_ad_preview.rb            # 2 layouts × 3 themes = 6 scenarios
    ├── agent_ad_preview.rb            # 2 layouts × 3 themes = 6 scenarios
    ├── collection_ad_preview.rb       # 1 layout × 3 themes = 3 scenarios
    └── theme_comparison_preview.rb    # Side-by-side all themes for one ad
```

**Preview scenario count:** ~22 ad previews total.

### Step 8 — Shared partial previews (secondary)

```
spec/components/previews/
└── shared/
    ├── page_header_preview.rb    # default, with_back_link, with_actions
    └── flash_preview.rb          # notice, alert, warning, info
```

Simpler stubs — these use plain locals, not model instances.

### Step 9 — Makefile + CLAUDE.md updates

Add informational `make lookbook` target. Add Lookbook section to CLAUDE.md documenting where previews live and how to add new ones.

---

## Verification

1. `make build` — gems install without conflict
2. `make up` — server starts, no errors in logs
3. Visit `http://replay.localhost:3000/lookbook` — gallery loads
4. Click through Listing Ad → Hero Just Listed — ad renders with dark theme, container-query sizing, correct badge
5. Toggle between themes in the theme comparison preview — CSS variables swap correctly
6. Verify DaisyUI classes render correctly (buttons, badges) in the preview iframe

---

## Extension: ViewComponent Conversion Priority for Ads

### Why convert at all?

Partials work fine for previewing, but ViewComponents add:
- **Testable in isolation** — unit test rendering without controller context
- **Typed interface** — `initialize` params replace implicit `locals` contracts
- **Sidecar assets** — colocate CSS/JS/templates per component
- **Slots** — composable content injection (useful for ad content inside layouts)

### Conversion priority (highest value first)

| Priority | Partial → Component | Why |
|----------|---------------------|-----|
| **1** | `.ad-canvas` wrapper → `Ads::CanvasComponent` | Every layout duplicates the same outer div, `style=` attribute with `ad_theme_style`, and `aspect-video` setup. A single component encapsulates theme application, container-query setup, and the image overlay pattern. All 6 layouts become simpler. |
| **2** | Layout partials → `Ads::Layouts::HeroComponent`, `SplitComponent`, etc. | Each layout becomes a component that accepts an `ad` and renders inside `CanvasComponent`. The `content` slot replaces the `render "app/ads/#{ad.adable_partial_path}/content"` dispatch. |
| **3** | `_qr_badge.html.erb` → `Ads::QrBadgeComponent` | Used by hero + split layouts. Small, self-contained, good first component to build confidence. |
| **4** | Ad content partials → `Ads::Content::ListingAdComponent`, etc. | Formalizes the data contract for each ad type's content block. Makes badge rendering independently testable. |
| **5** | `_page_header.html.erb` → `Shared::PageHeaderComponent` | Used on every app page. The `actions` block maps perfectly to a ViewComponent slot. |

### Suggested approach

- Convert **one component at a time**, starting with `QrBadgeComponent` (priority 3) as a low-risk proof of concept
- Keep the ERB partial as a thin wrapper during migration: `<%= render Ads::QrBadgeComponent.new(ad: ad) %>`
- Update the Lookbook preview to render the component directly
- Once all callers use the component, delete the partial
- Move to `CanvasComponent` (priority 1) next — highest deduplication value

### Component file structure

```
app/components/
└── ads/
    ├── canvas_component.rb
    ├── canvas_component.html.erb
    ├── qr_badge_component.rb
    ├── qr_badge_component.html.erb
    ├── layouts/
    │   ├── hero_component.rb
    │   ├── hero_component.html.erb
    │   ├── split_component.rb
    │   └── ...
    └── content/
        ├── listing_ad_component.rb
        ├── listing_ad_component.html.erb
        └── ...
```

Tests go in `spec/components/ads/` mirroring the structure.
