# Implementation Plan: Ad Templates v4 (Delegated Types)

_Execution plan for `plan-ad-templates-v4.md`. Follows agent-os/standards._

## Standards in effect

- **TDD**: Failing spec (RED) before implementation (GREEN). Factories in the RED step.
- **Commit cadence**: RED and GREEN are separate commits. Prefix with `(RED):` / `(GREEN):`.
- **Migrations**: `t.timestamps` first in all `create_table` blocks.
- **Seeds**: Idempotent, use FactoryBot, one deterministic record per model.
- **Thin controllers**: Params + redirect only. Business logic in models.
- **Tenant scoping**: All queries through `Current.account`.
- **Makefile**: Use `make test`, `make migrate`, `make seed`, etc.

---

## Phase A — Schema (type-specific tables + models)

### Task 1 (RED): ListingAd model spec + factory
- Write `spec/models/listing_ad_spec.rb`
  - Validates `badge` inclusion in `BADGES`
  - Validates `listing` presence
  - Conditional: `event_date` + `event_start_time` required when `open_house?`
  - Conditional: `original_price` required when `price_reduction?`
  - Conditional: `sold_price` required when `just_sold?`
  - `LAYOUTS` constant contains `hero`, `split`, `minimal`, `stat_grid`
  - `badge_label` returns human label
  - `default_headline` returns badge label
- Write `spec/factories/listing_ads.rb`
- Run spec → confirm RED
- Commit: `Task 1 (RED): ListingAd model spec + factory`

### Task 2 (GREEN): ListingAd migration + model
- Migration: `create_table :listing_ads`
  - `t.timestamps`
  - `t.references :listing, null: false, foreign_key: true`
  - `t.string :badge, null: false, default: "just_listed"`
  - `t.date :event_date`
  - `t.time :event_start_time`
  - `t.time :event_end_time`
  - `t.integer :original_price`
  - `t.integer :sold_price`
  - `t.date :sold_date`
- Create `app/models/listing_ad.rb` with validations, constants, badge methods
- `make migrate` → `make test-file FILE=spec/models/listing_ad_spec.rb` → confirm GREEN
- Commit: `Task 2 (GREEN): ListingAd model + migration`

### Task 3 (RED): CollectionAd model spec + factory
- Write `spec/models/collection_ad_spec.rb`
  - Validates `collection_title` presence
  - `LAYOUTS` constant contains `grid`
  - `default_headline` returns `collection_title`
  - Validates member count (2..8) via `collection_ad_ads`
- Write `spec/factories/collection_ads.rb`
- Run spec → confirm RED
- Commit: `Task 3 (RED): CollectionAd model spec + factory`

### Task 4 (GREEN): CollectionAd migration + model
- Migration: `create_table :collection_ads`
  - `t.timestamps`
  - `t.string :collection_title, null: false`
- Create `app/models/collection_ad.rb`
- `make migrate` → run spec → confirm GREEN
- Commit: `Task 4 (GREEN): CollectionAd model + migration`

### Task 5 (RED): CollectionAdAd model spec + factory
- Write `spec/models/collection_ad_ad_spec.rb`
  - Belongs to `collection_ad`
  - Belongs to `ad`
  - Unique index on `[collection_ad_id, ad_id]`
- Write `spec/factories/collection_ad_ads.rb`
- Run spec → confirm RED
- Commit: `Task 5 (RED): CollectionAdAd model spec + factory`

### Task 6 (GREEN): CollectionAdAd migration + model
- Migration: `create_table :collection_ad_ads`
  - `t.timestamps`
  - `t.references :collection_ad, null: false, foreign_key: { to_table: :collection_ads }`
  - `t.references :ad, null: false, foreign_key: true`
  - `t.integer :position, null: false, default: 0`
  - Indexes: unique on `[collection_ad_id, ad_id]`, on `[collection_ad_id, position]`
- Create `app/models/collection_ad_ad.rb`
- Run spec → confirm GREEN
- Commit: `Task 6 (GREEN): CollectionAdAd model + migration`

### Task 7 (RED): AgentAd model spec + factory
- Write `spec/models/agent_ad_spec.rb`
  - Validates `agent` presence
  - `LAYOUTS` constant contains `profile`, `split`
  - `default_headline` returns agent name
- Write `spec/factories/agent_ads.rb`
- Run spec → confirm RED
- Commit: `Task 7 (RED): AgentAd model spec + factory`

### Task 8 (GREEN): AgentAd migration + model
- Migration: `create_table :agent_ads`
  - `t.timestamps`
  - `t.references :agent, null: false, foreign_key: true`
- Create `app/models/agent_ad.rb`
- Run spec → confirm GREEN
- Commit: `Task 8 (GREEN): AgentAd model + migration`

### Task 9 (RED): BrandAd model spec + factory
- Write `spec/models/brand_ad_spec.rb`
  - `LAYOUTS` constant contains `hero`, `minimal`
  - No required associations
- Write `spec/factories/brand_ads.rb`
- Run spec → confirm RED
- Commit: `Task 9 (RED): BrandAd model spec + factory`

### Task 10 (GREEN): BrandAd migration + model
- Migration: `create_table :brand_ads`
  - `t.timestamps`
- Create `app/models/brand_ad.rb`
- Run spec → confirm GREEN
- Commit: `Task 10 (GREEN): BrandAd model + migration`

---

## Phase B — Wire Ad base with delegated types

### Task 11 (RED): Ad model spec updates
- Update `spec/models/ad_spec.rb`
  - `delegated_type :adable` with all four types
  - Validates `theme` inclusion in `THEMES`
  - Validates `layout` inclusion delegated to `adable.class::LAYOUTS`
  - `allowed_layouts` delegates to adable
  - `apply_defaults` sets headline, layout, theme from adable
  - `has_many :collection_ad_ads, dependent: :restrict_with_error`
  - Cannot delete an Ad that is referenced by a CollectionAdAd
- Update `spec/factories/ads.rb` to build with an adable (e.g. `association :adable, factory: :listing_ad`)
- Run spec → confirm RED
- Commit: `Task 11 (RED): Ad delegated type spec updates`

### Task 12 (GREEN): Ad migration + model changes
- Migration: add `adable_type`, `adable_id`, `layout`, `theme` to `ads`
  - `add_column :ads, :adable_type, :string`
  - `add_column :ads, :adable_id, :bigint`
  - `add_column :ads, :layout, :string, null: false, default: "hero"`
  - `add_column :ads, :theme, :string, null: false, default: "dark"`
  - `add_index :ads, [:adable_type, :adable_id]`
- Data migration: backfill existing ads → create ListingAd records, set adable
- Migration: remove `listing_id` from `ads`
- Update `app/models/ad.rb` with `delegated_type`, validations, `allowed_layouts`, `apply_defaults`
- Update existing scopes (`search` stays; remove `listing_ads`/`standalone` scopes)
- Run full spec suite → confirm GREEN
- Commit: `Task 12 (GREEN): Ad delegated types migration + model`

---

## Phase C — Seeds

### Task 13: Update seeds
- Update `db/seeds.rb` with idempotent seeds for each type
  - One deterministic ListingAd (just_listed badge, known listing)
  - One deterministic CollectionAd with 3 member ListingAds
  - One deterministic AgentAd (known agent)
  - One deterministic BrandAd
  - Additional Faker-backed records for variety
- `make seed` → verify
- Commit: `Update seeds for delegated ad types`

---

## Phase D — Layouts + themes

### Task 14: Layout partials + content partials + theme system
- Create layout partials in `app/views/ads/layouts/`:
  - `_hero.html.erb`, `_split.html.erb`, `_minimal.html.erb`
  - `_stat_grid.html.erb`, `_grid.html.erb`, `_profile.html.erb`
- Create content partials:
  - `app/views/ads/listing_ads/_content.html.erb`
  - `app/views/ads/collection_ads/_content.html.erb`
  - `app/views/ads/agent_ads/_content.html.erb`
  - `app/views/ads/brand_ads/_content.html.erb`
- Add `.ad-canvas` CSS custom properties to `app/assets/tailwind/application.css`
- Create `app/helpers/ads_helper.rb` with `THEME_OVERRIDES` hash, `ad_theme_style`, `edit_ad_path`
- Replace hardcoded preview in `ads/show.html.erb` with `render "ads/layouts/#{@ad.layout}"`
- Commit: `Add layout partials, content partials, and theme system`

### Task 15: Wire playlist preview
- Update `playlists/preview.html.erb` to render ads via layout partials
- Verify slideshow controller still works
- Commit: `Wire playlist preview to use layout partials`

---

## Phase E — Routes + controllers (RED/GREEN per type)

### Task 16 (RED): ListingAds request spec
- Write `spec/requests/ads/listing_ads_spec.rb`
  - GET new — renders form
  - POST create — valid params creates ListingAd + Ad, redirects
  - POST create — invalid params re-renders with errors
  - GET edit — renders form with existing data
  - PATCH update — valid params updates, redirects
  - Tenant scoping: cannot access other account's ads
- Run spec → confirm RED
- Commit: `Task 16 (RED): ListingAds request spec`

### Task 17 (GREEN): ListingAds controller + routes + views
- Add to `config/routes.rb`:
  ```ruby
  namespace :ads do
    resources :listing_ads, only: %i[new create edit update]
  end
  ```
- Create `app/controllers/ads/listing_ads_controller.rb`
  - Split params: `ad_params` (headline, body, layout, theme) + `listing_ad_params`
  - Build adable + ad together
  - Tenant scope via `Current.account`
- Create views: `ads/listing_ads/new.html.erb`, `edit.html.erb`, `_form.html.erb`
  - Compose shared partials: `ads/shared/_errors`, `_preview_canvas`, `_appearance_fields`, `_content_fields`, `_form_actions`
  - Badge selector with Stimulus toggle for conditional fields
- Run spec → confirm GREEN
- Commit: `Task 17 (GREEN): ListingAds controller, routes, views`

### Tasks 18-19: CollectionAds (RED then GREEN)
### Tasks 20-21: AgentAds (RED then GREEN)
### Tasks 22-23: BrandAds (RED then GREEN)

_Same pattern as Tasks 16-17 for each type._

### Task 24: Update AdsController + type chooser
- Update `ads#new` to render type chooser tiles
- Update `ads#index` filter: `params[:ad_type]` filtering on `adable_type`
- Update show page edit link to use `edit_ad_path(@ad)` helper
- Run full suite
- Commit: `Update AdsController with type chooser and delegated type routing`

---

## Phase F — Polish

### Task 25: Index cards + thumbnails
- Update ad card on `ads/index.html.erb` to use layout partials for thumbnails
- Update playlist timeline thumbnails
- Commit: `Update ad index cards and playlist thumbnails to use layout partials`

### Task 26: Lint + full suite
- `make lint-fix`
- `make test`
- Fix any issues
- Commit: `Lint fixes`
