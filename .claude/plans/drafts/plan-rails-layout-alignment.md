# Plan: Align Rails listing ad layouts with React compositions

## Context

React now uses composition-based rendering with `Overlay` and `Split` layouts (landscape + portrait). Rails still defines `LAYOUTS = %w[hero split minimal stat_grid]` and existing records use `hero`. This plan renames `hero` → `overlay`, removes `minimal` and `stat_grid` (no React compositions), and updates all references.

## Step 1: Migration — rename `hero` to `overlay` in existing records

```ruby
class RenameHeroToOverlayOnAds < ActiveRecord::Migration[8.1]
  def up
    Ad.where(layout: "hero").update_all(layout: "overlay")
  end

  def down
    Ad.where(layout: "overlay").update_all(layout: "hero")
  end
end
```

### Files
- Create: `db/migrate/XXXX_rename_hero_to_overlay_on_ads.rb`

## Step 2: Update ListingAd model

Change `LAYOUTS` from `%w[hero split minimal stat_grid]` to `%w[overlay split]`.

### Files
- Modify: `app/models/ads/listing_ad.rb` — `LAYOUTS` constant

## Step 3: Update Ad model defaults

`apply_defaults` sets `layout = allowed_layouts.first` when blank. After the LAYOUTS change, the default becomes `"overlay"` automatically. No code change needed, but verify `allowed_layouts` fallback in `ad.rb` — currently defaults to `%w[hero]`, change to `%w[overlay]`.

### Files
- Modify: `app/models/ad.rb` — change fallback from `%w[hero]` to `%w[overlay]`

## Step 4: Update BrandAd layouts

BrandAd currently has `LAYOUTS = %w[hero minimal]`. Rename `hero` → `overlay`. Keep `minimal` for BrandAd since it's a different ad type with its own rendering (unchanged old components).

### Files
- Modify: `app/models/ads/brand_ad.rb` — `%w[hero minimal]` → `%w[overlay minimal]`

## Step 5: Update ERB layout partials

Rename `_hero.html.erb` → `_overlay.html.erb` so the dynamic render `render "app/ads/layouts/#{ad.layout}"` resolves correctly.

### Files
- Rename: `app/views/app/ads/layouts/_hero.html.erb` → `_overlay.html.erb`

## Step 6: Delete unused layout partials

`minimal` and `stat_grid` are no longer in ListingAd::LAYOUTS. However:
- `_minimal.html.erb` is still used by BrandAd and AgentAd (via `MinimalLayout`)
- `_stat_grid.html.erb` is only used by ListingAd — delete it

### Files
- Delete: `app/views/app/ads/layouts/_stat_grid.html.erb`

## Step 7: Update seeds

Replace all `layout: "hero"` with `layout: "overlay"` in `db/seeds.rb`. Remove any seeds that use `layout: "minimal"` or `layout: "stat_grid"` for listing ads.

### Files
- Modify: `db/seeds.rb`

## Step 8: Update factories

Change ad factory default from `layout: "hero"` to `layout: "overlay"`.

### Files
- Modify: `spec/factories/ads.rb`

## Step 9: Update specs

- Any specs referencing `layout: "hero"` for listing ads → `layout: "overlay"`
- Any specs testing `minimal` or `stat_grid` layouts for listing ads → remove or update
- Model spec for ListingAd validations — update expected LAYOUTS

### Files
- Modify: `spec/models/ads/listing_ad_spec.rb` (if exists, or `spec/models/listing_ad_spec.rb`)
- Modify: any request specs referencing hero/minimal/stat_grid for listing ads

## Step 10: Update React alias

Remove the `hero` alias from `LISTING_COMPOSITIONS` in AdRenderer since all records are now `overlay`.

### Files
- Modify: `player-app/src/components/ads/AdRenderer/index.tsx` — remove `hero` entry

## Summary of layout state after this plan

| Ad Type | LAYOUTS | React compositions |
|---------|---------|-------------------|
| ListingAd | `overlay`, `split` | `listings/Overlay/`, `listings/Split/` |
| AgentAd | `profile`, `split` | `AgentAd/` (old structure) |
| BrandAd | `overlay`, `minimal` | `BrandAd/` (old structure) |
| CollectionAd | `grid` | `CollectionAd/` (old structure) |

## Verification

1. `make migrate` — data migration runs
2. `make test` — all Rails specs pass
3. `npm run build` — React build clean
4. `npx vitest run` — all JS tests pass
5. Storybook renders Overlay and Split correctly
6. `make seed` — seeds run without errors
