# Plan: Complete Listing Ad Layout System

## Context

We've built the composition architecture (elements + layout × aspect) with Overlay and Split. This plan completes all 9 listing ad layouts from the visual spec, adds the Rails alignment (rename hero → overlay), and removes the other ad types entirely. Only ListingAd remains.

## What's already done

- Composition architecture: `ads/listings/{Layout}/{Landscape,Portrait}/`
- Shared elements: Badge, Price, Address, Specs, AgentStrip, QrCode, PhotoWrap
- AdCanvas: dual-scale typography (landscape/portrait), 3 themes
- AdRenderer: layout × aspect dispatch for listing ads
- Storybook: global theme toggle, stories for Overlay and Split
- Structured address: street, city, state, zip, neighborhood on Listing model

## Layouts to build (7 remaining)

From the visual spec (`listing-ads-visual-spec.md`):

| # | Layout | Photos | Description |
|---|--------|--------|-------------|
| 1 | ~~Overlay~~ | 1 | Done |
| 2 | ~~Split~~ | 1 | Done |
| 3 | Band | 1 | Photo top 68%, solid bar bottom with inline content |
| 4 | Card | 1 | Full-bleed photo, floating surface panel bottom-left |
| 5 | Type + Photo | 0–1 | Photo as texture under wash, large address |
| 6 | Stat Grid | 1 | Photo right, 2×2 stat grid left |
| 7 | Mosaic | 3 | 3 photos left (1 large + 2 stacked), text column right |
| 8 | Diptych | 2 | 2 photos side by side, bridging text bar bottom |
| 9 | Sequence | 3 | Overlay geometry + crossfade between 3 photos |

Each gets Landscape + Portrait = 14 new composition files.

## Execution order

Build single-photo layouts first (most listings have 1 photo), then multi-photo:

### Phase 1: Single-photo layouts (Band, Card, Type+Photo, Stat Grid)
For each layout:
1. Create `ads/listings/{Layout}/Landscape/index.tsx`
2. Create `ads/listings/{Layout}/Portrait/index.tsx`
3. Add Storybook stories for both
4. Add to `LISTING_COMPOSITIONS` map in AdRenderer
5. Build passes → commit

### Phase 2: Multi-photo layouts (Mosaic, Diptych, Sequence)
Same pattern. Sequence adds CSS crossfade animation (opacity + transform only).

Listing photos come from `listing.photos[]` in the manifest (already served).

### Phase 3: Rails alignment
Promote `plan-rails-layout-alignment.md`:
- Migration: rename `hero` → `overlay` in all ad records
- Update `ListingAd::LAYOUTS` to all 9 layout names
- Update seeds, factories, specs
- Rename `_hero.html.erb` → `_overlay.html.erb`
- Add ERB partials for new layouts (or skip if we're moving to React preview)

### Phase 4: Remove other ad types
Remove AgentAd, BrandAd, and CollectionAd from both Rails and React. Only ListingAd remains.

**Rails:**
- Remove `Ads::AgentAd` model, controller, views, factory, specs
- Remove `Ads::BrandAd` model, controller, views, factory, specs
- Remove `Ads::CollectionAd` model, controller, views, factory, specs
- Remove `Ads::CollectionAdAd` join model
- Update `Ad` delegated_type to only `%w[Ads::ListingAd]`
- Update `AdRenderer` switch in React to only handle ListingAd
- Migration to drop `ads_agent_ads`, `ads_brand_ads`, `ads_collection_ads`, `ads_collection_ad_ads` tables
- Clean up seeds — remove non-listing ad entries

**React:**
- Delete `ads/AgentAd/`
- Delete `ads/BrandAd/`
- Delete `ads/CollectionAd/`
- Delete `ads/layouts/` (MinimalLayout, StatGridLayout, GridLayout, HeroLayout, SplitLayout — all only used by removed ad types)
- Remove their imports from AdRenderer
- Update Slideshow stories that reference mockAgentAd/mockBrandAd

### Phase 5: Cleanup
- Remove `hero` alias from React AdRenderer
- Remove unused mock helpers (mockAgentAd, mockBrandAd, mockCollectionAd)
- Remove unused TypeScript types (ManifestAgentAd, ManifestBrandAd, ManifestCollectionAd)

## New elements needed

- **StatBlock** — 2×2 grid of large figures (beds, baths, sqft, year/lot) for Stat Grid layout
- **ProgressTicks** — horizontal tick indicators for Sequence (which photo is showing)

## Files per layout (template)

```
ads/listings/{Layout}/
  Landscape/index.tsx
  Landscape/{Layout}Landscape.stories.tsx
  Portrait/index.tsx
  Portrait/{Layout}Portrait.stories.tsx
```

## Out of scope

- Photo fallback chain (layout downgrade when photos are missing)
- Form builder React preview (separate plan exists)
- Sequence animation implementation (CSS-only, can be added after static structure)

## Verification

Per layout:
1. `npm run build` passes
2. `npx vitest run` — all tests pass
3. Storybook renders both aspects correctly
4. Theme toggle works across all 3 themes

Final:
1. `make test` — Rails specs pass after alignment
2. All 9 layouts × 2 aspects × 3 themes render in Storybook
