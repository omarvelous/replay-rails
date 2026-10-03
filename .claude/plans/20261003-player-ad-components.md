# Plan: React Player — Ad Components & Component Organization

**Created:** 2026-10-02
**Status:** Draft
**Branch:** TBD

## Problem

The React player handles only 2 of 4 ad types and ignores the `layout`
field entirely. All ad rendering is inline in `Slideshow.tsx`. As we add
layouts and ad types, the file would become unmanageable.

**Current gaps:**

| Ad type | Status | Issue |
|---|---|---|
| `Ads::ListingAd` | Partial | `layout` ignored — hero/split/minimal/stat_grid all identical |
| `Ads::AgentAd` | Partial | `layout` ignored — profile/split/minimal all identical |
| `Ads::BrandAd` | Stub | Falls through to generic headline/body — no image |
| `Ads::CollectionAd` | Missing | Not handled at all |

**Organization issue:** `Slideshow.tsx` owns rotation timing, ad dispatch,
and ad rendering in one 175-line file with private functions. Ad components
can't be developed or tested in isolation.

## CSS Variable System

The Rails signage views use a CSS variable system for theme and
container-query-based sizing. The React player should use the same system
so ad renders match the Rails preview.

### Theme variables (`--ad-*`)

Applied inline via `style` on the root ad container based on `ad.theme`:

```typescript
// Dark (default)
"--ad-bg": "#0b0d12",
"--ad-text": "#ffffff",
"--ad-text-muted": "rgba(255,255,255,0.6)",
"--ad-text-faint": "rgba(255,255,255,0.45)",
"--ad-accent": "#5b8eff",
"--ad-surface": "rgba(255,255,255,0.1)",

// Light
"--ad-bg": "#f9fafb",
"--ad-text": "#111827",
"--ad-text-muted": "#4b5563",
"--ad-text-faint": "#6b7280",
"--ad-accent": "#2f6bff",
"--ad-surface": "#ffffff",
```

### Sizing variables (`--s-*`)

Set once on the `.ad-canvas` container element via `container-type: inline-size`.
All sizes derive from `cqw` (container query width units):

```css
--s-xs: 1cqw;    --s-sm: 1.3cqw;   --s-base: 1.8cqw;
--s-lg: 2.2cqw;  --s-xl: 2.6cqw;   --s-2xl: 3.2cqw;
--s-3xl: 4cqw;   --s-4xl: 5cqw;    --s-hero: 7cqw;
--s-pad: 5cqw;   --s-pad-lg: 7cqw; --s-gap: 1.5cqw;
--s-qr: 8cqw;    --s-avatar: 15cqw;
--s-badge-px: 1.2cqw; --s-badge-py: 0.4cqw;
```

These go in `ads/AdCanvas.tsx` — a thin wrapper that sets the container
query context and injects both `--ad-*` and `--s-*` variables.

## New Component Structure

Each component lives in its own folder with `index.tsx` as the entry point
and co-located stories + tests.

```
components/
  PlayerShell/                  — root orchestrator
    index.tsx
  screens/                      — full-screen state UIs (no content)
    PairingScreen/
      index.tsx
      PairingScreen.stories.tsx
      PairingScreen.test.tsx
    IdleScreen/
      index.tsx
      IdleScreen.stories.tsx
      IdleScreen.test.tsx
    ErrorScreen/
      index.tsx
      ErrorScreen.stories.tsx
      ErrorScreen.test.tsx
  playback/                     — content renderers (receive manifest, render it)
    Slideshow/
      index.tsx                 — rotation + progress bar only
      Slideshow.stories.tsx
      Slideshow.test.tsx
    Experience/
      index.tsx
      Experience.stories.tsx
      Experience.test.tsx
  ads/
    AdCanvas/
      index.tsx                 — container query context + theme + sizing vars
    AdRenderer/
      index.tsx                 — dispatches type → content, layout → wrapper
    shared/
      AgentStrip/
        index.tsx               — avatar + name + phone
        AgentStrip.stories.tsx
      Badge/
        index.tsx               — colored chip: just_listed, open_house, etc.
        Badge.stories.tsx
    layouts/
      HeroLayout/
        index.tsx               — full-screen bg + gradient + bottom content
        HeroLayout.stories.tsx
      SplitLayout/
        index.tsx               — 50/50: image left, content right
        SplitLayout.stories.tsx
      MinimalLayout/
        index.tsx               — no image, centered, theme bg (covers profile)
        MinimalLayout.stories.tsx
      StatGridLayout/
        index.tsx               — vertically centered, no image (agents)
        StatGridLayout.stories.tsx
      GridLayout/
        index.tsx               — collection grid
        GridLayout.stories.tsx
    ListingAd/
      index.tsx                 — badge, price, address, specs, open house
      ListingAd.stories.tsx
      ListingAd.test.tsx
    AgentAd/
      index.tsx                 — photo, name, phone, email, body
      AgentAd.stories.tsx
      AgentAd.test.tsx
    BrandAd/
      index.tsx                 — headline + body (MinimalLayout only for now)
      BrandAd.stories.tsx
    CollectionAd/
      index.tsx                 — adaptive grid of listing cards
      CollectionAd.stories.tsx
      CollectionAd.test.tsx
```

## AdRenderer Architecture

`AdRenderer` composes layout + content:

```tsx
// AdRenderer.tsx
export function AdRenderer({ ad }: { ad: ManifestPlaylistAd }) {
  const content = contentFor(ad)
  const agentStrip = agentStripFor(ad)

  return (
    <AdCanvas theme={ad.theme}>
      {layoutFor(ad.layout, { ad, content, agentStrip })}
    </AdCanvas>
  )
}
```

`contentFor` dispatches on `adable.type`:
- `Ads::ListingAd` → `<ListingAdContent>`
- `Ads::AgentAd` → `<AgentAdContent>`
- `Ads::BrandAd` → `<BrandAdContent>`
- `Ads::CollectionAd` → `<CollectionAdContent>`

`layoutFor` dispatches on `ad.layout`:
- `hero` → `<HeroLayout>`
- `split` → `<SplitLayout>`
- `minimal` | `profile` → `<MinimalLayout>`
- `stat_grid` → `<StatGridLayout>`
- `grid` → `<GridLayout>`

Each layout receives `ad` (for the background image), `content`, and
optionally `agentStrip`.

## Component Reorganization

Move existing flat files into the folder-per-component structure. Logic
unchanged — rename/move only.

| From | To |
|---|---|
| `components/PlayerShell.tsx` | `components/PlayerShell/index.tsx` |
| `components/PairingScreen.{tsx,stories,test}` | `components/screens/PairingScreen/` |
| `components/IdleScreen.{tsx,stories,test}` | `components/screens/IdleScreen/` |
| `components/ErrorScreen.{tsx,stories,test}` | `components/screens/ErrorScreen/` |
| `components/Slideshow.{tsx,stories,test}` | `components/playback/Slideshow/` |
| `components/Experience.{tsx,stories,test}` | `components/playback/Experience/` |

Update imports in `App.tsx` and `PlayerShell` after the move.

## Slideshow Cleanup

After extraction, `Slideshow.tsx` drops to ~60 lines and only owns:
- The `currentIndex` / `progress` state
- The auto-advance timer
- The progress bar animation
- `<AdRenderer ad={currentAd} />`

The `AdContent`, `ListingAdContent` private functions are deleted.

## Layout Specs (from Rails partials)

### HeroLayout
- Full-screen background image (`object-cover`)
- Gradient overlay: `linear-gradient(to top, rgba(0,0,0,0.7) 0%, transparent 60%)`
- Content + agentStrip anchored to bottom with `--s-pad` padding
- Used by: ListingAd (hero), AgentAd (hero), BrandAd (when image present)

### SplitLayout
- Left 50%: background image, `object-cover`
- Right 50%: content + agentStrip, vertically centered, `--s-pad-lg` padding
- Used by: ListingAd (split), AgentAd (split)

### MinimalLayout
- `var(--ad-bg)` fill, `var(--ad-text)` color
- Content centered both axes
- No image
- Used by: AgentAd (minimal), BrandAd (minimal), BrandAd (profile)

### StatGridLayout
- `var(--ad-bg)` fill
- Content vertically centered, left-aligned
- No image
- Used by: AgentAd (stat_grid)

### GridLayout
- `var(--ad-bg)` fill, `--s-pad-lg` padding
- Title + count header
- Adaptive grid: 2 columns ≤4 items, 3 columns >4 items
- Each card: image top, price + address + specs bottom
- Used by: CollectionAd (always grid)

## Badge Colors

```typescript
const BADGE_COLORS: Record<string, string> = {
  just_listed:     "bg-green-500",
  open_house:      "bg-amber-500",
  just_sold:       "bg-red-500",
  price_reduction: "bg-orange-500",
  coming_soon:     "bg-purple-500",
}
```

## CollectionAd Notes

`CollectionAd` is a static grid — all sub-ads shown simultaneously, no
internal rotation. This was decision: option 1 (nested slideshow deferred).

The `ad.headline` field is the collection title (already in manifest).
The sub-ads come from `adable.collection_ads: ManifestPlaylistAd[]`.
Each card renders: image, price, address, specs (same fields as ListingAd
but smaller scale).

## Out of Scope

- QR badges — no QR data in the React player manifest
- Theme switching UI — `ad.theme` is applied but no user control
- Nested slideshow for CollectionAd (deferred)
- `Ads::BrandAd` hero/split layouts — BrandAd uses MinimalLayout only
  for now; image support and additional layouts are a future addition
- Moving existing top-level components (PairingScreen, IdleScreen,
  ErrorScreen, Slideshow, Experience) into folders — plan covers ads/ only

## Execution

```
1. Reorganize existing components into folder structure
   PlayerShell/, screens/, playback/ — move + update imports
   COMMIT

2. Add ads/AdCanvas/ — container query context + CSS variables
   COMMIT

3. Add ads/shared/Badge/ + ads/shared/AgentStrip/
   COMMIT

4. Add ads/layouts/ — HeroLayout, SplitLayout, MinimalLayout,
   StatGridLayout, GridLayout (each as a folder)
   COMMIT

5. Add ad content components — ListingAd/, AgentAd/, BrandAd/,
   CollectionAd/ (each as a folder)
   COMMIT

6. Add ads/AdRenderer/ — wires layout + content dispatch
   COMMIT

7. Refactor playback/Slideshow/ — replace AdContent/ListingAdContent
   with <AdRenderer>, delete private functions
   COMMIT
```
