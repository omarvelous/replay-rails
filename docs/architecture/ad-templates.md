# Ad Template System

Ads use Rails delegated types to support 4 distinct ad formats, each with their own layouts, validations, and content rendering.

## Delegated types

`Ad` is the parent record. It delegates type-specific behavior to an "adable" subclass:

```ruby
class Ad < ApplicationRecord
  delegated_type :adable, types: %w[
    Ads::ListingAd
    Ads::CollectionAd
    Ads::AgentAd
    Ads::BrandAd
  ]
end
```

Each adable lives in its own table and has `has_one :ad, as: :adable`. Rails generates type-checking methods: `ad.listing_ad?`, `ad.agent_ad`, etc.

## Ad types

### Listing ad (`Ads::ListingAd`)

Created from a property listing. Shows property details, photos, and price.

| Field | Description |
|-------|-------------|
| `listing_id` | FK to the source listing |
| `badge` | Optional badge overlay |
| Layouts | `hero`, `split`, `minimal`, `stat_grid` |

**Badges:** `just_listed`, `open_house`, `just_sold`, `price_reduction`, `coming_soon`. Some badges require additional fields:

- `open_house` → `event_date`, `event_time`
- `price_reduction` → `original_price`
- `just_sold` → `sold_price`

### Collection ad (`Ads::CollectionAd`)

Groups up to 8 existing ads into a grid layout.

| Field | Description |
|-------|-------------|
| `collection_ad_ads` | Join table linking member ads |
| Layouts | `grid` |
| Max items | 8 |

### Agent ad (`Ads::AgentAd`)

Spotlight ad for a real estate agent.

| Field | Description |
|-------|-------------|
| `agent_id` | FK to the agent |
| Layouts | `profile`, `split` |

### Brand ad (`Ads::BrandAd`)

Freeform ad for brokerage branding.

| Field | Description |
|-------|-------------|
| `headline`, `body` | Custom copy |
| Layouts | `hero`, `minimal` |

## Layout system

Each adable class defines a `LAYOUTS` constant. The `Ad` record stores the chosen layout in a `layout` column.

Rendering chain:

```
Layout partial (hero, split, etc.)
  └── Content partial (listing_ads/_content, agent_ads/_content, etc.)
```

Layout partials live in `app/views/app/ads/layouts/`:

| Partial | Used by | Description |
|---------|---------|-------------|
| `_hero` | ListingAd, BrandAd | Full-bleed image, gradient overlay, content bottom-left |
| `_split` | ListingAd, AgentAd | Left half image, right half content |
| `_minimal` | ListingAd, BrandAd | Centered content, no background image |
| `_stat_grid` | ListingAd | Vertically centered property stats |
| `_grid` | CollectionAd | Flex grid of member ads |
| `_profile` | AgentAd | Centered agent photo and details |
| `_qr_badge` | (shared) | Inline SVG QR code, bottom-right corner |

## Themes

Three themes control the color palette via CSS custom properties:

| Theme | Description |
|-------|-------------|
| `dark` | Dark background, light text (default) |
| `light` | Light background, dark text |
| `brand` | Account brand colors |

Applied via `ad_theme_style(theme)` helper which sets inline CSS custom properties: `--ad-bg`, `--ad-text`, `--ad-text-muted`, `--ad-accent`, `--ad-surface`.

## Creating an ad

The `Ads::` namespace controllers handle creation for each type:

```
POST /ads/listing_ads    → Ads::ListingAdsController#create
POST /ads/collection_ads → Ads::CollectionAdsController#create
POST /ads/agent_ads      → Ads::AgentAdsController#create
POST /ads/brand_ads      → Ads::BrandAdsController#create
```

Each controller creates the adable record first, then builds the parent `Ad` record with layout, theme, and image. The generic `AdsController` handles index, show, edit, update, destroy, and preview.

## Preview

`GET /ads/:id/preview` renders the ad in the signage layout at full resolution. Used for proofing before publishing to a playlist.
