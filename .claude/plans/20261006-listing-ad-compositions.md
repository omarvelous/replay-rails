# Plan: Composition-based Listing Ad Architecture

## Context

The current React ad system uses layout components (`HeroLayout`, `SplitLayout`, etc.) that receive pre-built content as `children`. This means layouts can't control where individual elements (badge, price, QR) are placed — they just wrap a content blob. The HTML prototype at `public/ad-composer.html` proved that each layout × aspect is a genuinely different composition with different element placement.

This plan restructures listing ads into **composition components** — one per layout per aspect — using shared **element components** for the reusable pieces. It also updates the theme and typography systems to match the design spec.

## Folder structure

```
player-app/src/components/ads/
  AdCanvas/index.tsx           ← updated: dual-scale typography, new theme values
  AdRenderer/index.tsx         ← updated: aspect detection, composition dispatch
  elements/                    ← NEW: shared building blocks
    Badge/index.tsx
    Price/index.tsx
    Address/index.tsx
    Specs/index.tsx
    AgentStrip/index.tsx
    QrCode/index.tsx
    PhotoWrap/index.tsx
  Overlay/                     ← NEW: composition per aspect
    Landscape/index.tsx
    Portrait/index.tsx
  Split/                       ← NEW: composition per aspect
    Landscape/index.tsx
    Portrait/index.tsx
  AgentAd/index.tsx            ← unchanged for now
  BrandAd/index.tsx            ← unchanged for now
  CollectionAd/index.tsx       ← unchanged for now
```

Delete after migration:
```
  layouts/HeroLayout/          ← replaced by Overlay/
  layouts/SplitLayout/         ← replaced by Split/
  layouts/MinimalLayout/       ← keep (used by AgentAd, BrandAd)
  layouts/StatGridLayout/      ← keep (used by AgentAd)
  layouts/GridLayout/          ← keep (used by CollectionAd)
  shared/Badge/                ← moved to elements/Badge
  shared/AgentStrip/           ← moved to elements/AgentStrip
  ListingAd/                   ← replaced by compositions
```

## Phase 1: Theme + typography update in AdCanvas

Update `AdCanvas/index.tsx` to match the design spec.

**Theme values** (from `listing-ads-visual-spec.md`):

```ts
const THEME_VARS = {
  dark: {
    "--ad-bg": "#0B0D12",
    "--ad-text": "#FFFFFF",
    "--ad-text-muted": "rgba(255,255,255,0.72)",
    "--ad-text-faint": "rgba(255,255,255,0.52)",
    "--ad-accent": "#5B9BFF",
    "--ad-surface": "#161A22",
    "--scrim": "linear-gradient(to top, #0B0D12 0%, rgba(11,13,18,0.85) 30%, transparent 55%)",
  },
  light: {
    "--ad-bg": "#F7F8FA",
    "--ad-text": "#0B0D12",
    "--ad-text-muted": "#5B6470",
    "--ad-text-faint": "#6B7380",
    "--ad-accent": "#2F6BFF",
    "--ad-surface": "#FFFFFF",
    "--scrim": "linear-gradient(to top, #F7F8FA 0%, rgba(247,248,250,0.85) 30%, transparent 55%)",
  },
  brand: {
    "--ad-bg": "#14273F",
    "--ad-text": "#FFFFFF",
    "--ad-text-muted": "rgba(255,255,255,0.72)",
    "--ad-text-faint": "rgba(255,255,255,0.52)",
    "--ad-accent": "#7FA8D9",
    "--ad-surface": "#1C3350",
    "--scrim": "linear-gradient(to top, #14273F 0%, rgba(20,39,63,0.85) 30%, transparent 55%)",
  },
}
```

**Typography — dual scale by aspect** (from spec table):

```ts
const SIZING_LANDSCAPE = {
  "--t-price": "5.6cqw", "--t-address": "3.4cqw", "--t-sub": "1.5cqw",
  "--t-spec": "1.4cqw", "--t-spec-grid": "2.4cqw", "--t-spec-label": "1.0cqw",
  "--t-badge": "1.1cqw", "--t-agent-name": "1.2cqw", "--t-agent-detail": "1.0cqw",
  "--t-mark": "1.3cqw",
  "--safe": "3.2cqw", "--qr-size": "6.5cqw", "--avatar": "3.4cqw",
  "--gap": "1.2cqw", "--gap-sm": "0.6cqw",
}

const SIZING_PORTRAIT = {
  "--t-price": "11cqw", "--t-address": "7cqw", "--t-sub": "3.4cqw",
  "--t-spec": "3.2cqw", "--t-spec-grid": "5cqw", "--t-spec-label": "2cqw",
  "--t-badge": "2.4cqw", "--t-agent-name": "2.6cqw", "--t-agent-detail": "2.2cqw",
  "--t-mark": "2.6cqw",
  "--safe": "6cqw", "--qr-size": "15cqw", "--avatar": "7cqw",
  "--gap": "2.4cqw", "--gap-sm": "1.2cqw",
}
```

`AdCanvas` accepts a new `aspect` prop and merges the right sizing scale.

### Files
- Modify: `player-app/src/components/ads/AdCanvas/index.tsx`

---

## Phase 2: Elements

Shared, stateless components. Each owns its own styling via the `--t-*` CSS variables set by AdCanvas. These are the *what* — compositions decide the *where*.

### `elements/Badge/index.tsx`
- Props: `badge: string`, `label: string`
- Color map: `just_sold` → teal, `coming_soon` → teal per spec, others use `--ad-accent`

### `elements/Price/index.tsx`
- Props: `price: number`, `originalPrice?: number`, `soldPrice?: number`, `badge?: string`
- Handles 3 variants: standard, price-reduction (strikethrough), just-sold (sold price + "Listed at")

### `elements/Address/index.tsx`
- Props: `address: string`, `neighborhood?: string`

### `elements/Specs/index.tsx`
- Props: `beds?: number`, `baths?: number`, `sqft?: number`
- Inline format: `4 bd · 3 ba · 3,240 sqft`

### `elements/AgentStrip/index.tsx`
- Props: `agent: ManifestAgent`, `pill?: boolean` (pill style for Overlay)

### `elements/QrCode/index.tsx`
- Placeholder for now — white square with dark inner, sized with `--qr-size`

### `elements/PhotoWrap/index.tsx`
- Props: `src?: string`, `scrim?: boolean`
- Absolutely positioned photo + optional scrim overlay using `--scrim` CSS var

### Files
- Create: 7 files in `player-app/src/components/ads/elements/`

---

## Phase 3: Compositions — Overlay

### `Overlay/Landscape/index.tsx`
- PhotoWrap (full-bleed + scrim)
- Top row: agent strip (left), QR (right)
- Bottom content: badge → address → specs → price (left), brokerage mark (right)

### `Overlay/Portrait/index.tsx`
- PhotoWrap (full-bleed + scrim)
- Top row: agent strip (left), QR (right)
- Bottom content: badge → address → specs → price (stacked, full-width)

### Files
- Create: `player-app/src/components/ads/Overlay/Landscape/index.tsx`
- Create: `player-app/src/components/ads/Overlay/Portrait/index.tsx`

---

## Phase 4: Compositions — Split

### `Split/Landscape/index.tsx`
- Photo column (58%) with QR in upper-right corner
- Text column (42%): badge → address → specs (top), price + agent strip (bottom, space-between)

### `Split/Portrait/index.tsx`
- Photo area (top 52%), QR in upper-right
- Text area (bottom 48%): badge → address → specs (top), price + agent strip (bottom, space-between)

### Files
- Create: `player-app/src/components/ads/Split/Landscape/index.tsx`
- Create: `player-app/src/components/ads/Split/Portrait/index.tsx`

---

## Phase 5: Aspect detection + AdRenderer dispatch

### Aspect detection
```ts
// player-app/src/utils/useAspect.ts
export function useAspect(): "landscape" | "portrait" {
  return window.innerWidth >= window.innerHeight ? "landscape" : "portrait"
}
```

### AdRenderer update
Listing ads dispatch by `layout × aspect`. Other ad types unchanged.

```tsx
const LISTING_COMPOSITIONS = {
  overlay:   { landscape: OverlayLandscape,  portrait: OverlayPortrait },
  split:     { landscape: SplitLandscape,    portrait: SplitPortrait },
  hero:      { landscape: OverlayLandscape,  portrait: OverlayPortrait }, // alias
}
```

### Files
- Create: `player-app/src/utils/useAspect.ts`
- Modify: `player-app/src/components/ads/AdRenderer/index.tsx`

---

## Phase 6: Cleanup

### Delete (replaced by compositions)
- `player-app/src/components/ads/layouts/HeroLayout/`
- `player-app/src/components/ads/layouts/SplitLayout/`
- `player-app/src/components/ads/ListingAd/`

### Delete (moved to elements/)
- `player-app/src/components/ads/shared/Badge/`
- `player-app/src/components/ads/shared/AgentStrip/`

### Keep (still used by AgentAd, BrandAd, CollectionAd)
- `player-app/src/components/ads/layouts/MinimalLayout/`
- `player-app/src/components/ads/layouts/StatGridLayout/`
- `player-app/src/components/ads/layouts/GridLayout/`

### Update imports
- `AgentAd` and `CollectionAd` reference `shared/` — update to `elements/`

---

## Theme handling — how it flows

1. **Manifest** serves `ad.theme` (`"dark"`, `"light"`, or `"brand"`)
2. **AdRenderer** reads `ad.theme` and `useAspect()`
3. **AdCanvas** receives both, merges `THEME_VARS[theme]` + `SIZING_[LANDSCAPE|PORTRAIT]` into inline CSS variables on the container div
4. **Elements** read from CSS variables — they don't know about theme or aspect
5. **Compositions** arrange elements and use CSS variables for spacing — they also don't know about theme

Theme is fully decoupled from composition. A composition doesn't render differently for dark vs light — only the CSS variable values change.

**Brand theme note:** Currently hardcoded with example values. To make it dynamic per brokerage, the manifest would need to include the brokerage's primary color — future work.

---

## Verification

1. `npm run build` in `player-app/` — no TypeScript errors
2. Open player in both landscape and portrait browser windows
3. Verify Overlay renders: badge above address, QR upper-right, price below specs
4. Verify Split renders: photo left/top, text right/bottom, QR on photo upper-right
5. Toggle themes in seed data — dark/light/brand all apply correct colors
6. Verify `hero` layout alias still works (old records)
7. Verify AgentAd, BrandAd, CollectionAd still render (unchanged)
