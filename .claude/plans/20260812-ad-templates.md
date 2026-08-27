# Plan: Ad Templates (v4 — delegated types)

_Supersedes `plan-ad-templates-v3.md`._

## What changed from v3

- **Delegated types instead of STI** — each type gets its own table with only its columns. No nullable column bloat as types grow.
- **CollectionAd groups any Ad, not just ListingAd** — supports "Meet the Team" (AgentAds) or mixed collections in the future.
- **Theme vars as a hash lookup** — no case statement.
- **Deletion protection** — an Ad referenced by a CollectionAd cannot be deleted.
- **Convention-based edit routing** — `adable_name` drives the URL, no case statement helper.

---

## The object model (unchanged from v3)

```
Ad (base — common fields)
├── ListingAd       One listing. Badge: just_listed | open_house | sold | price_reduction | coming_soon
├── CollectionAd    Multiple ads. "Open Houses This Weekend"
├── AgentAd         One agent. Profile / spotlight
└── BrandAd         Freeform. Headline + body + image. No listing, no agent.
```

---

## Implementation: Delegated Types

Each type gets its own table. The `ads` table holds common fields and a polymorphic
`adable_type` / `adable_id` pair pointing to the type-specific record.

### The `ads` table (common)

```ruby
# migration
change_table :ads do |t|
  t.string  :adable_type, null: false
  t.bigint  :adable_id,   null: false
  t.string  :layout,      null: false, default: "hero"
  t.string  :theme,       null: false, default: "dark"
end
add_index :ads, %i[adable_type adable_id]

# listing_id is removed after data migration (it moves to listing_ads table)
```

Common fields that stay on `ads`: `account_id`, `headline`, `body`, `layout`, `theme`.

### Type-specific tables

```ruby
create_table :listing_ads do |t|
  t.timestamps
  t.references :listing, null: false, foreign_key: true
  t.string  :badge,            null: false, default: "just_listed"
  t.date    :event_date
  t.time    :event_start_time
  t.time    :event_end_time
  t.integer :original_price
  t.integer :sold_price
  t.date    :sold_date
end

create_table :collection_ads do |t|
  t.timestamps
  t.string :collection_title, null: false
end

create_table :agent_ads do |t|
  t.timestamps
  t.references :agent, null: false, foreign_key: true
end

create_table :brand_ads do |t|
  t.timestamps
end
```

Each table has only the columns that type needs. No nulls, no bloat. Adding a
future `MarketStatsAd` or `TestimonialAd` is a new table + model — zero impact
on existing tables.

### Backfill existing data

```ruby
Ad.find_each do |ad|
  listing_ad = ListingAd.create!(listing_id: ad.listing_id)
  ad.update_columns(adable_type: "ListingAd", adable_id: listing_ad.id, layout: "hero", theme: "dark")
end
# then: remove_reference :ads, :listing
```

---

## The models

### `Ad` (base)

```ruby
# app/models/ad.rb
class Ad < ApplicationRecord
  belongs_to :account
  delegated_type :adable, types: %w[ListingAd CollectionAd AgentAd BrandAd], dependent: :destroy

  has_many :playlist_ads, dependent: :destroy
  has_many :playlists, through: :playlist_ads
  has_many :collection_ad_ads, dependent: :restrict_with_error  # prevent deletion if in a collection

  THEMES = %w[dark light brand].freeze

  validates :headline, presence: true
  validates :theme, inclusion: { in: THEMES }
  validates :layout, inclusion: { in: ->(ad) { ad.allowed_layouts } }

  scope :search, ->(q) { where("ads.headline ILIKE ?", "%#{sanitize_sql_like(q)}%") }

  def allowed_layouts
    adable&.class::LAYOUTS || %w[hero]
  end

  def apply_defaults
    self.headline = adable&.default_headline if headline.blank?
    self.layout = allowed_layouts.first if layout.blank?
    self.theme = "dark" if theme.blank?
  end
end
```

`delegated_type` gives us: `ad.listing_ad?`, `ad.collection_ad?`, `ad.adable_name`
(returns `"listing_ad"`, `"collection_ad"`, etc.), and `ad.adable` (the type record).

### `ListingAd`

```ruby
# app/models/listing_ad.rb
class ListingAd < ApplicationRecord
  BADGES  = %w[just_listed open_house just_sold price_reduction coming_soon].freeze
  LAYOUTS = %w[hero split minimal stat_grid].freeze

  BADGE_LABELS = {
    "just_listed"     => "Just Listed",
    "open_house"      => "Open House",
    "just_sold"       => "Just Sold",
    "price_reduction" => "Price Reduced",
    "coming_soon"     => "Coming Soon",
  }.freeze

  has_one :ad, as: :adable, dependent: :destroy, touch: true

  belongs_to :listing

  validates :badge, inclusion: { in: BADGES }
  validates :listing, presence: true

  with_options if: :open_house? do
    validates :event_date,       presence: true
    validates :event_start_time, presence: true
  end

  with_options if: :price_reduction? do
    validates :original_price, presence: true, numericality: { greater_than: 0 }
  end

  with_options if: :just_sold? do
    validates :sold_price, presence: true, numericality: { greater_than: 0 }
  end

  def default_headline = BADGE_LABELS[badge]
  def badge_label      = BADGE_LABELS[badge]

  def open_house?      = badge == "open_house"
  def just_sold?       = badge == "just_sold"
  def price_reduction? = badge == "price_reduction"
  def coming_soon?     = badge == "coming_soon"
  def just_listed?     = badge == "just_listed"
end
```

### `CollectionAd`

Groups any `Ad` records — ListingAds, AgentAds, or a mix.

```ruby
# app/models/collection_ad.rb
class CollectionAd < ApplicationRecord
  LAYOUTS = %w[grid].freeze
  MAX_ITEMS = 8

  has_one :ad, as: :adable, dependent: :destroy, touch: true

  has_many :collection_ad_ads, dependent: :destroy
  has_many :member_ads, through: :collection_ad_ads, source: :ad

  validates :collection_title, presence: true
  validate  :member_count_in_range

  def default_headline = collection_title

  # Auto-set layout since grid is the only option
  after_initialize -> { self.ad&.layout = "grid" if ad&.layout.blank? }

  private

    def member_count_in_range
      count = collection_ad_ads.size
      if count < 2
        errors.add(:base, "needs at least 2 ads")
      elsif count > MAX_ITEMS
        errors.add(:base, "can have at most #{MAX_ITEMS} ads")
      end
    end
end
```

### `AgentAd`

```ruby
# app/models/agent_ad.rb
class AgentAd < ApplicationRecord
  LAYOUTS = %w[profile split].freeze

  has_one :ad, as: :adable, dependent: :destroy, touch: true

  belongs_to :agent

  validates :agent, presence: true

  def default_headline = agent&.name
end
```

### `BrandAd`

```ruby
# app/models/brand_ad.rb
class BrandAd < ApplicationRecord
  LAYOUTS = %w[hero minimal].freeze

  has_one :ad, as: :adable, dependent: :destroy, touch: true

  def default_headline = nil
end
```

---

## The `CollectionAdAd` join table

Connects a `CollectionAd` to any `Ad`. This means a collection can contain
ListingAds, AgentAds, BrandAds, or a mix. The FK on `ad_id` points to the
`ads` table — no type restriction at the DB level, just the natural polymorphism.

```ruby
# migration
create_table :collection_ad_ads do |t|
  t.timestamps
  t.references :collection_ad, null: false, foreign_key: { to_table: :collection_ads }
  t.references :ad,            null: false, foreign_key: true
  t.integer    :position,      null: false, default: 0
end
add_index :collection_ad_ads, %i[collection_ad_id ad_id], unique: true
add_index :collection_ad_ads, %i[collection_ad_id position]
```

```ruby
# app/models/collection_ad_ad.rb
class CollectionAdAd < ApplicationRecord
  belongs_to :collection_ad
  belongs_to :ad
end
```

### Deletion protection

An `Ad` that belongs to a collection cannot be deleted:

```ruby
# On Ad (already shown above)
has_many :collection_ad_ads, dependent: :restrict_with_error
```

Attempting to delete raises a validation error: "Cannot delete ad because it is
part of a collection." The user must remove it from the collection first.

---

## Layout partials

Each type defines `LAYOUTS` as a constant. Partials live under `app/views/ads/layouts/`:

```
app/views/ads/layouts/
├── _hero.html.erb         # ListingAd, BrandAd
├── _split.html.erb        # ListingAd, AgentAd
├── _minimal.html.erb      # ListingAd, BrandAd
├── _stat_grid.html.erb    # ListingAd
├── _grid.html.erb         # CollectionAd
└── _profile.html.erb      # AgentAd
```

Rendering:

```erb
<%= render "ads/layouts/#{@ad.layout}", ad: @ad %>
```

Content is delegated to the type's folder via `adable_name`:

```erb
<%# ads/layouts/_hero.html.erb %>
<div class="ad-canvas preview-frame relative flex flex-col justify-end p-10"
     style="background: var(--ad-bg); color: var(--ad-text); <%= ad_theme_style(ad.theme) %>">
  <%= render "ads/#{ad.adable_name.pluralize}/content", ad: ad %>
</div>
```

`ad.adable_name` returns `"listing_ad"` → renders `ads/listing_ads/_content.html.erb`.

Content partials access type-specific data through `ad.adable`:

```erb
<%# ads/listing_ads/_content.html.erb %>
<% listing_ad = ad.adable %>
<div style="color: var(--ad-accent);" class="text-xs font-bold tracking-widest mb-2">
  <%= listing_ad.badge_label.upcase %>
</div>
<div class="text-5xl font-extrabold tracking-tight">
  <%= number_to_currency(listing_ad.listing.price, precision: 0) %>
</div>
<div style="color: var(--ad-text-muted);" class="text-lg mt-2">
  <%= listing_ad.listing.address %>
</div>
```

---

## Themes: CSS custom properties with inline overrides

### 1. Stylesheet defaults (dark theme)

```css
/* app/assets/tailwind/application.css */
.ad-canvas {
  --ad-bg: #0b0d12;
  --ad-text: #ffffff;
  --ad-text-muted: rgba(255, 255, 255, 0.5);
  --ad-text-faint: rgba(255, 255, 255, 0.3);
  --ad-accent: #2f6bff;
  --ad-surface: rgba(255, 255, 255, 0.1);
}
```

Dark theme needs zero inline styles — the CSS handles it.

### 2. Theme helper (hash lookup, no case statement)

```ruby
# app/helpers/ads_helper.rb
module AdsHelper
  THEME_OVERRIDES = {
    "dark" => {},
    "light" => {
      "--ad-bg"         => "#f9fafb",
      "--ad-text"       => "#111827",
      "--ad-text-muted" => "#6b7280",
      "--ad-text-faint" => "#9ca3af",
      "--ad-surface"    => "#ffffff",
    },
    "brand" => {
      "--ad-bg"         => :accent,
      "--ad-text"       => "#ffffff",
      "--ad-text-muted" => "rgba(255, 255, 255, 0.6)",
      "--ad-text-faint" => "rgba(255, 255, 255, 0.4)",
      "--ad-surface"    => "rgba(255, 255, 255, 0.1)",
    },
  }.freeze

  def ad_theme_style(theme, accent: "#2f6bff")
    overrides = THEME_OVERRIDES.fetch(theme, {})
    overrides
      .map { |k, v| "#{k}: #{v == :accent ? accent : v}" }
      .join("; ")
  end
end
```

The `:accent` sentinel is replaced at render time with the account's brand color.
Adding a new theme = one new entry in the hash.

### 3. Where the accent color comes from

Hardcoded to `#2f6bff` for now. Eventually `Account` gets a `brand_color` column:

```erb
<%= ad_theme_style(ad.theme, accent: Current.account.brand_color) %>
```

### 4. Badge colors are NOT themed

Badges use their own semantic colors (green, red, amber) regardless of theme.

---

## Routes

```ruby
# config/routes.rb
namespace :ads do
  resources :listing_ads,    only: %i[new create edit update]
  resources :collection_ads, only: %i[new create edit update]
  resources :agent_ads,      only: %i[new create edit update]
  resources :brand_ads,      only: %i[new create edit update]
end

resources :ads, only: %i[index show destroy] do
  member do
    get :preview
  end
end
```

```
GET    /ads                           → ads#index       (all types)
GET    /ads/:id                       → ads#show        (any type, via Ad id)
DELETE /ads/:id                       → ads#destroy
GET    /ads/:id/preview               → ads#preview

GET    /ads/listing_ads/new           → ads/listing_ads#new
POST   /ads/listing_ads               → ads/listing_ads#create
GET    /ads/listing_ads/:id/edit      → ads/listing_ads#edit
PATCH  /ads/listing_ads/:id           → ads/listing_ads#update
```

`show`, `destroy`, and `preview` use the `Ad` id. `new`, `create`, `edit`,
`update` use the `Ad` id too — the type-specific controller finds the Ad and
works through `ad.adable`.

---

## Controllers

### `AdsController` (shared)

```ruby
# app/controllers/ads_controller.rb
class AdsController < ApplicationController
  before_action :set_ad, only: %i[show destroy preview]

  def index
    # existing search/filter/pagination
  end

  def show
  end

  def new
    # renders type chooser tiles
  end

  def preview
    render layout: "preview"
  end

  def destroy
    @ad.destroy
    redirect_to ads_path, notice: t(".success")
  end

  private

    def set_ad
      @ad = Current.account.ads.find(params[:id])
    end
end
```

### `Ads::ListingAdsController`

```ruby
# app/controllers/ads/listing_ads_controller.rb
module Ads
  class ListingAdsController < ApplicationController
    before_action :set_ad, only: %i[edit update]

    def new
      @listing_ad = ListingAd.new
      @ad = @listing_ad.build_ad(account: Current.account)
      @ad.apply_defaults
    end

    def create
      @listing_ad = ListingAd.new(listing_ad_params)
      @ad = @listing_ad.build_ad(ad_params.merge(account: Current.account))
      @ad.apply_defaults

      if @listing_ad.save
        redirect_to @ad, notice: t(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @listing_ad = @ad.adable
    end

    def update
      @listing_ad = @ad.adable
      @listing_ad.assign_attributes(listing_ad_params)
      @ad.assign_attributes(ad_params)

      if @listing_ad.save && @ad.save
        redirect_to @ad, notice: t(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

      def set_ad
        @ad = Current.account.ads.find(params[:id])
      end

      def ad_params
        params.require(:ad).permit(:headline, :body, :layout, :theme)
      end

      def listing_ad_params
        params.require(:listing_ad).permit(
          :listing_id, :badge,
          :event_date, :event_start_time, :event_end_time,
          :original_price, :sold_price, :sold_date
        )
      end
  end
end
```

Same pattern for the other type controllers. Each splits params into `ad_params`
(common) and type-specific params. No case statements anywhere.

---

## Edit routing (convention-based, no case statement)

`adable_name` (provided by `delegated_type`) drives the URL:

```ruby
# app/helpers/ads_helper.rb
def edit_ad_path(ad)
  send("edit_ads_#{ad.adable_name}_path", ad)
end
```

`ad.adable_name` returns `"listing_ad"` → `edit_ads_listing_ad_path(ad)` → `/ads/listing_ads/:id/edit`.

Used in views:

```erb
<%= link_to "Edit", edit_ad_path(@ad), class: "..." %>
```

---

## Directory structure

```
app/
├── controllers/
│   ├── ads_controller.rb                    # index, show, destroy, preview, new (chooser)
│   └── ads/
│       ├── listing_ads_controller.rb
│       ├── collection_ads_controller.rb
│       ├── agent_ads_controller.rb
│       └── brand_ads_controller.rb
│
├── models/
│   ├── ad.rb                                # base (delegated_type :adable)
│   ├── listing_ad.rb                        # own table: listing_ads
│   ├── collection_ad.rb                     # own table: collection_ads
│   ├── collection_ad_ad.rb                  # join: collection_ad_ads
│   ├── agent_ad.rb                          # own table: agent_ads
│   └── brand_ad.rb                          # own table: brand_ads
│
├── views/
│   └── ads/
│       ├── index.html.erb                   # shared (all types)
│       ├── show.html.erb                    # shared (all types)
│       ├── new.html.erb                     # type chooser tiles
│       ├── preview.html.erb                 # shared preview
│       ├── shared/                          # shared form partials
│       │   ├── _errors.html.erb
│       │   ├── _preview_canvas.html.erb
│       │   ├── _appearance_fields.html.erb
│       │   ├── _content_fields.html.erb
│       │   └── _form_actions.html.erb
│       ├── layouts/                         # visual layouts
│       │   ├── _hero.html.erb
│       │   ├── _split.html.erb
│       │   ├── _minimal.html.erb
│       │   ├── _stat_grid.html.erb
│       │   ├── _grid.html.erb
│       │   └── _profile.html.erb
│       ├── listing_ads/
│       │   ├── new.html.erb
│       │   ├── edit.html.erb
│       │   ├── _form.html.erb
│       │   └── _content.html.erb
│       ├── collection_ads/
│       │   ├── new.html.erb
│       │   ├── edit.html.erb
│       │   ├── _form.html.erb
│       │   └── _content.html.erb
│       ├── agent_ads/
│       │   ├── new.html.erb
│       │   ├── edit.html.erb
│       │   ├── _form.html.erb
│       │   └── _content.html.erb
│       └── brand_ads/
│           ├── new.html.erb
│           ├── edit.html.erb
│           ├── _form.html.erb
│           └── _content.html.erb
```

---

## Form flow

### Step 1 — Type chooser

```
GET /ads/new → ads#new → ads/new.html.erb
```

Four tiles linking to resourceful paths:

```
/ads/listing_ads/new
/ads/collection_ads/new
/ads/agent_ads/new
/ads/brand_ads/new
```

### Step 2 — Type-specific form

Each type's form splits into two param groups — `ad` (common) and the type
(e.g. `listing_ad`). Shared partials handle the common fields.

### ListingAd form fields

```
- Badge selector   (radio tiles: Just Listed | Open House | Sold | Price Drop | Coming Soon)
- Listing picker    (single select, scoped to Current.account)
- Headline          (pre-filled from badge, editable)
- Body              (optional)
- Layout picker     (hero / split / minimal / stat_grid)
- Theme picker      (dark / light / brand)

If badge = open_house:
  - Event date, start time, end time

If badge = price_reduction:
  - Original price

If badge = just_sold:
  - Sold price, sold date
```

### CollectionAd form fields

```
- Collection title  ("Open Houses This Weekend")
- Ad picker         (multi-select from existing Ads, reorder, max 8)
- Theme picker      (layout is auto-set to grid)
```

### AgentAd form fields

```
- Agent picker      (single select, scoped to Current.account)
- Headline          (pre-filled with agent name)
- Body              (optional)
- Layout picker     (profile / split)
- Theme picker
```

### BrandAd form fields

```
- Headline          (freeform)
- Body              (freeform)
- Layout picker     (hero / minimal)
- Theme picker
```

---

## Index + filtering

```ruby
# ads_controller.rb
base = base.where(adable_type: params[:ad_type]) if params[:ad_type].present?
```

Select options: All / Listing / Collection / Agent / Brand

No collision with a `type` column — delegated types uses `adable_type`.

---

## Migration plan (build order)

### Phase A — Schema
1. Create `listing_ads`, `collection_ads`, `agent_ads`, `brand_ads` tables
2. Create `collection_ad_ads` join table
3. Add `adable_type`, `adable_id`, `layout`, `theme` to `ads`
4. Backfill: create `ListingAd` records from existing `ads.listing_id`, update `adable_type`/`adable_id`
5. Remove `listing_id` from `ads`
6. Create model files with delegated type wiring

### Phase B — Layouts + themes
7. Create layout partials (`_hero`, `_split`, `_minimal`, `_stat_grid`, `_grid`, `_profile`)
8. Create content partials per type (`listing_ads/_content`, etc.)
9. Add `.ad-canvas` CSS custom properties to `application.css`
10. Create `AdsHelper` with `THEME_OVERRIDES` hash and `ad_theme_style`
11. Replace hardcoded preview in `ads/show.html.erb` and `playlists/preview.html.erb`

### Phase C — Forms + routes
12. Add namespaced routes and type-specific controllers
13. Build type chooser on `ads/new.html.erb`
14. Build type-specific form partials (compose shared partials)
15. Build badge selector with conditional fields (Stimulus)
16. Build ad picker for CollectionAd

### Phase D — Polish
17. Update index cards and playlist thumbnails
18. Update filter select on ads index
19. Add `edit_ad_path` helper using `adable_name`

---

## Why delegated types over STI

| Concern | STI | Delegated Types |
|---------|-----|-----------------|
| New type added | Nullable columns added to shared table | New table, zero impact on existing |
| Table cleanliness | Grows with every type | Each table has only its columns |
| Queries | `Ad.all` just works | `Ad.all` just works (same) |
| Associations | `playlist_ads` just works | `playlist_ads` just works (same) |
| Type-specific FKs | All in one table, nullable | Real FKs with NOT NULL on own table |
| Future ceiling | Painful at 10+ types | Scales indefinitely |

The cost is one extra join when loading type-specific data (`ad.adable`), and
slightly more ceremony in controllers (two param groups). Worth it for the
clean separation.

---

## Why this is the right set of primitives

**Adding a new badge** = add to `ListingAd::BADGES`, add a label, optionally add
`with_options` validations. No migration if no new columns.

**Adding a new ad type** = new table, new model, new controller, new partials.
Zero impact on existing types or the `ads` table.

**Adding a new layout** = new partial, add to the relevant type's `LAYOUTS` constant.

**Adding a new theme** = one new entry in `THEME_OVERRIDES` hash.

Each axis (type, badge, layout, theme) is independently extensible.

---

## What's deferred

- **Inline ListingAd creation from CollectionAd form** — Currently requires pre-existing ListingAds; future workflow could create them inline
- **Auto-create from listing events** — When listing status → "sold", prompt to create a ListingAd with badge `just_sold`
- **Listing photo in layouts** — Depends on image uploads plan
- **Template marketplace** — Account-customizable templates stored as DB records
- **AI copy generation** — Auto-headline/body from listing data per badge
- **UUID migration** — Tenant scoping on create will be fully addressed when switching to UUIDs
