# Listing Ad — layout system handoff (Claude Code)

Adopt the new Listing Ad layouts from `specs/Listing Ad Composer.html` into the admin builder and playback, scoped to **Dark + Light themes** and **10 layouts**. Read `CLAUDE.md` and `SPEC.md` first — the no-build / babel-scope / load-order rules apply.

## Source of truth

`specs/Listing Ad Composer.html` — the `<style>` block from `/* AD ENGINE */` through `/* LAYOUT: Diptych */`, plus the `ad()` markup function. Port that CSS **verbatim** (selectors, cqmin values, portrait `@container` blocks). Do not re-derive sizes.

## Scope

**Themes (2):** `dark` (default, any daypart), `light` (day only). Keep `editorial`, `luxe`, `bold`, `gallery`, `brand` in `AD_THEMES` but don't expose them on Listing Ads yet.

**Layouts (10):**

| id | Name | Composer class | Media | Notes |
|---|---|---|---|---|
| `overlay` | Overlay | `L-ov` | photo ×1 | Renamed from `hero`. Default. |
| `split` | Split | `L-sp` | photo ×1 | Spec grid (`.sp.grd`). |
| `band` | Band | `L-bd` | photo ×1 | |
| `card` | Card | `L-cd` | photo ×1 | Spec grid. CTA text hidden. |
| `mosaic` | Mosaic | `L-mo` | photo ×3 | |
| `poster` | Poster | `L-po` | photo ×1 | Agent chip hidden in portrait. |
| `typePhoto` | Type + Photo | `L-ty ty-ph` | photo ×1 (backdrop) | Type grid + wash. Spec grid. |
| `map` | Map split | `L-mp` | photo ×1 + map | Map = static image of `listing.lat/lng`. |
| `sequence` | Sequence | `L-ov L-sq` | photo ×3 | Overlay geometry + crossfade. |
| `diptych` | Diptych | `L-dp` | photo ×2 | Exterior + interior. |

**Out of scope:** plain `Type` (no photo) and `Plan split`. Don't add them to `AD_LAYOUTS`. Note: the composer CSS for `typePhoto` depends on the `.L-ty` rules — port those, just don't register `type` as a selectable layout.

## 1 · Model changes — `admin/js/ad-model.jsx`

1. Rename `hero` → `overlay` everywhere (`AD_LAYOUTS`, `AD_TEMPLATES`, `AD_RECORDS`, `resolveLayout` default). Add `hero:"overlay"` to `AD_LAYOUT_ALIAS` so old records still load.
2. Add the new layout entries using the same contract shape (`media`, `aspects`, `safeArea`, `roles`, `repeating`, `blurb`). Add these fields:
   - `cls` — the CSS class string from the table.
   - `media:{min,max}` — from the table. `map` adds `requiresMap:true`.
   - `aspects:["16:9","9:16"]` for all 10. (No 1:1 / 21:9 geometry exists — `checkAd` will error on those, which is correct.)
   - `specStyle:"grid"|"inline"` — grid for `split`, `card`, `typePhoto`; inline for the rest. (Matches the composer's `["sp","cd","ty","pl"]` check.)
   - `motion:"sequence"` on `sequence` only.
   - `brandChip:boolean` — `false` for `overlay`, `sequence`, `typePhoto`; `true` for the rest (composer adds `.chip` when not ov/ty).
   - `category:"listing"` so the builder can filter.
3. Add `agent` to `roles` on all 10 (optional add-on, bound to `listing.agent`).
4. Theme tokens: make `AD_THEMES.dark.tokens` / `light.tokens` match the composer `.T-dark` / `.T-light` vars exactly (note dark `bg` is now flat `#0b0d12`, not a gradient). Add a `cssClass:"T-dark"` / `"T-light"` field. The stylesheet is the runtime truth; the JS tokens drive builder swatches only.
5. Data (`admin/js/data.jsx`): each listing needs `photos[]` (≥3), `agentId`, `lat`, `lng`, `year`, `type`. Add a hydrated `listing.photos`, `listing.mapImage`, `listing.agent` in `adContext`.

## 2 · Renderer — new `admin/js/ad-render.jsx`

One component, used by **both** the builder canvas and playback. Delete the inline `AdPreview` in `screens-ads.jsx`.

```
<ListingAd hydrated={hydrateAd(ad)} aspect="16:9" showAgent />
```

- Emits the composer markup 1:1 (`.ad > .in > .ph ×3, .scrim, .mp, .tk, .brand, .agent, .pn > .c / .k`). Class list: `ad ${layout.cls} ${theme.cssClass}`.
- Unused nodes (`.ph2`, `.mp`, `.tk`) can be omitted when the layout doesn't use them — the CSS hides them anyway.
- Agent visibility: replace the composer's `.board.ag .ad .agent` with a modifier on the ad itself: `.ad.has-agent .agent{display:flex}`. Same for Poster's `.board.ag .L-po .in` → `.L-po.has-agent .in`.
- Photos: `.ph` becomes `background-image:url(...)` + `background-size:cover`. Remove the striped placeholder pattern and the `::after` labels in production; keep them only when `photo` is missing (builder state).
- QR: real QR SVG from the existing QR helper, sized by the layout's `--q` var. Keep `--qrbg` quiet zone.
- Price: `adFormat` handles `/mo` — wrap the suffix in `<small>` as the composer does.
- Eyebrow default: `Just Listed` / `For Rent` from listing status; price label `Asking` / `Rent` (only rendered by themes that set `--pl:block`, i.e. not Dark/Light).
- Put the CSS in **`assets/ad-engine.css`** (new file). Load it in `admin/RePlay Admin.html` and in `playback/Playback Board.html`. Fonts: Inter Tight 400–700.
- Add `ad-render.jsx` to the load order **after `ad-model.jsx`, before `screens-*`**.

## 3 · Screen-display requirements

These are what make it work on a real panel, not just in a thumbnail. Every one is a hard requirement.

**Render size.** The ad element is always rendered at native panel pixels — 1920×1080 or 1080×1920 — then scaled with `transform:scale()` to fit a preview. Never render at thumbnail size and let cqmin shrink it: the composer's 576px cards are for comparison only. Builder canvas and playback both use a `FitStage` wrapper that does the scaling.

**Container queries stay.** `container-type:size` on `.ad`; portrait geometry comes from `@container (orientation:portrait)`, never from the `aspect` prop. A 9:16 window screen and a 16:9 lobby screen use the same markup.

**Safe area.** All text/QR is already inset ≥3.6cqmin (~39px at 1080). Add a per-screen `--overscan` (default `0`) that adds to every inset, for TVs that crop. Implement as `.ad .in{inset:var(--overscan,0)}` with photos still bleeding to the edge (`.ph` gets `inset:calc(var(--overscan)*-1)`).

**Legibility at 20 ft.** At 1080 short edge, 1cqmin ≈ 10.8px. Floors:
- Headline ≥ 6cqmin, price ≥ 5.6cqmin (all layouts pass).
- Any readable copy ≥ 1.8cqmin. **Fix:** Band landscape `.cta` is 1.7cqmin → raise to 1.8cqmin.
- QR ≥ 9cqmin (~97px; scannable from ~1.5 m). All pass.
- Headline: enforce `constraints.headline.maxChars` (34). Over the cap, `checkAd` warns and the renderer steps the headline down in 8% increments, max 2 steps, then truncates with ellipsis. Never wrap past 3 lines.

**Contrast.**
- Dark: text on scrim. The Overlay scrim is theme-colored (`color-mix` with `--bg`) so it works for both themes — keep it.
- Light: `checkAd` must warn when `light` is scheduled without a daytime daypart (rule exists — keep it). Add a playback guard: if a Light ad plays outside 07:00–19:00 local, swap to `dark` automatically and log it.
- Bright photos under Overlay/Sequence: apply a `brightness(.9)` filter to `.ph` in Dark only if image mean luminance > 0.6 (compute once at upload, store on the photo record).

**Motion (Sequence).**
- Cycle length = ad `duration` (not the hard-coded 9s). Set `--seq:${duration}s` and use it for both `sqf` and `tkf` animations; delays = `duration/3` and `2*duration/3`.
- Start the animation on slot entry (add `.playing` class from the playback runtime), not on DOM mount — otherwise preloading drifts it.
- Use only `opacity` and `transform` (GPU-safe on low-end players). No `filter` animation.
- `@media (prefers-reduced-motion)` / per-screen `reduceMotion` flag → crossfade without the scale push.
- Text, price, QR never move.

**Preloading.** Playback must preload all photos for the next ad before its slot starts; if any `media.min` photo fails to load, fall back per §4. Wait for `document.fonts.ready` once at boot.

**Burn-in.** Brand chip, QR, and price are static across loops. Add an optional per-screen `pixelShift` flag: shift `.in` by ±2px on each loop iteration.

**Composer-only styles to drop:** `.ad` box-shadow and border-radius (panels are full-bleed).

## 4 · Fallbacks (resolve at render, never error on a live screen)

| Layout | Missing | Falls back to |
|---|---|---|
| `mosaic`, `sequence` | < 3 photos | `diptych` if 2, else `overlay` |
| `diptych` | < 2 photos | `overlay` |
| `map` | no lat/lng | `split` |
| any | 0 photos | `typePhoto` with no `.ph` (wash over `--bg`) |

Implement in `hydrateAd` as `resolvedLayout`; the builder shows "Showing Overlay — needs 3 photos" when it differs from the chosen layout.

## 5 · Builder wiring — `admin/js/screens-ads.jsx`

- Layout picker: replace the inline `[["hero","Hero"],…]` list with `Object.values(AD_LAYOUTS).filter(l => l.category === "listing")`. Thumbnail = a live `<ListingAd>` at 16:9 scaled into the chip (or a static wireframe per layout — your call, but no hand-drawn SVG).
- Theme picker: `dark`, `light` only for Listing Ads. Swatch from `theme.tokens.bg`.
- Add **Aspect** toggle (16:9 / 9:16) and **Show agent** toggle above the canvas.
- Content panel edits slot values on the real ad record (`slots[]`) — drop the ad-hoc `{headline, sub, price…}` state.
- Media panel: shows N photo slots based on `layout.media.max`; Diptych labels them "Exterior" / "Interior".
- Switching layout calls `reconcileLayout` — never drop content.
- Lint panel: render `checkAd(ad)` issues under the canvas.

## 6 · Acceptance

- [ ] All 10 layouts × 2 themes × 2 aspects render in the builder and in `playback/Playback Board.html` and visually match the composer cells.
- [ ] Old records with `layout:"hero"` load as `overlay`.
- [ ] Rendered at 1920×1080 and 1080×1920, scaled to preview — no layout uses thumbnail-sized px.
- [ ] Sequence cycle tracks `duration`; text doesn't move; reduced-motion works.
- [ ] Every fallback in §4 triggers correctly (test by removing photos / lat-lng from a listing in `data.jsx`).
- [ ] Light ad outside daytime → plays as Dark in playback.
- [ ] Band CTA raised to 1.8cqmin; no readable text under 1.8cqmin.
- [ ] No global `const styles`; `app.jsx` still loads last; no console errors.
- [ ] Publish, billing, MLS sync remain placeholders — don't wire them.
