# Plan: Digital Signage CSS Fixes

_Based on `analysis-digital-signage-css.md`. Addresses contrast, readability,
performance, and layout issues identified against industry standards._

---

## Step 1 — Fix contrast and text scale tokens

Update `.ad-canvas` CSS custom properties in `application.css`:

```css
/* Before */
--ad-text-faint: rgba(255, 255, 255, 0.3);   /* 4.8:1 — borderline */
--ad-accent: #2f6bff;                         /* 4.2:1 — fails WCAG AA */
--s-base: 1.5cqw;                             /* 29px — below readable threshold */
--s-3xl: 3.5cqw;                              /* 67px — borderline for address */

/* After */
--ad-text-faint: rgba(255, 255, 255, 0.45);   /* ~6.5:1 — passes */
--ad-accent: #5b8eff;                          /* ~6.2:1 — passes */
--s-base: 1.8cqw;                              /* 35px — minimum readable */
--s-3xl: 4cqw;                                 /* 77px — comfortable for address */
```

Also update `THEME_OVERRIDES` in `AdsHelper` to bump the light theme faint
text and accent for outdoor readability:

```ruby
"light" => {
  "--ad-text-faint" => "#6b7280",  # was #9ca3af — too light for outdoor
}
```

**Files:** `app/assets/tailwind/application.css`, `app/helpers/ads_helper.rb`

---

## Step 2 — Enforce minimum font weight

Add `font-weight: 600` to `.ad-canvas` so all text inside ads is at least
semibold. Thin/regular weight text disappears at viewing distance.

```css
.ad-canvas {
  font-weight: 600;
}
```

Individual elements can still override to `font-extrabold` (800) for headlines.
Nothing inside the canvas should render below 600.

**Files:** `app/assets/tailwind/application.css`

---

## Step 3 — Center hero content when no image

The hero layout anchors content to the bottom (`justify-end`). This works when
a photo fills the top. Without a photo, the top 40% is empty gradient — wasted
space.

```erb
<%# Before — always bottom-anchored %>
<div class="ad-canvas aspect-video relative flex flex-col justify-end" ...>

<%# After — center when no image, bottom when image present %>
<div class="ad-canvas aspect-video relative flex flex-col <%= ad.image.attached? ? 'justify-end' : 'justify-center' %>" ...>
```

**Files:** `app/views/ads/layouts/_hero.html.erb`

---

## Step 4 — GPU-composite the progress bar

The slideshow progress bar currently animates `width`, which triggers layout
recalculation on every animation frame. On low-power player hardware running
24/7, this causes unnecessary CPU/GPU work.

Switch to `transform: scaleX()` which is GPU-composited:

```javascript
// Before — triggers layout
this.progressTarget.style.width = `${fraction * 100}%`

// After — GPU composited
this.progressTarget.style.transform = `scaleX(${fraction})`
```

The progress bar element needs `transform-origin: left` and a base `width: 100%`:

```erb
<div style="height: 100%; width: 100%; transform: scaleX(0); transform-origin: left;
            background: rgba(255,255,255,0.5);"
     data-slideshow-target="progress"></div>
```

**Files:** `app/javascript/controllers/slideshow_controller.js`,
`app/views/playlists/preview.html.erb`

---

## Step 5 — Add `contain: content` to slide containers

Tells the browser each slide's contents are independent of the rest of the page,
enabling paint and layout optimizations. Important for continuous operation.

```erb
<div class="slide absolute inset-0 ..."
     style="z-index: 1; contain: content;"
     ...>
```

**Files:** `app/views/playlists/preview.html.erb`

---

## Step 6 — Add sunlight warning to light theme

In the appearance fields shared partial, add a note under the light theme option
warning about outdoor readability:

```erb
<% if theme_name == "light" %>
  <span class="text-[10px] text-amber-600 block mt-0.5">May be hard to read in sunlight</span>
<% end %>
```

**Files:** `app/views/ads/shared/_appearance_fields.html.erb`

---

## Step 7 — Remove text usage of smallest tokens

Audit all content partials for usage of `--s-sm` and `--s-xs` as `font-size`.
These tokens should only be used for spacing (`margin`, `padding`, `gap`).
Replace any text usage with `--s-base` minimum.

Current usages to check:
- QR placeholder text uses `--s-sm` — acceptable (decorative, not informational)
- Badge `padding` uses `--s-badge-py` / `--s-badge-px` — these are spacing, OK
- `gap` and `margin-top` uses of `--s-xs` — spacing, OK

**Files:** All content partials in `app/views/ads/*/`

---

## Build order

| Step | Risk | Effort | Files changed |
|------|------|--------|---------------|
| 1 — Contrast + scale tokens | High — outdoor readability | 10 min | 2 |
| 2 — Font weight floor | High — distance readability | 2 min | 1 |
| 3 — Hero centering | Medium — visual improvement | 5 min | 1 |
| 4 — Progress bar GPU | Medium — player performance | 10 min | 2 |
| 5 — `contain: content` | Low — performance optimization | 2 min | 1 |
| 6 — Sunlight warning | Low — UX guidance | 5 min | 1 |
| 7 — Token audit | Low — correctness | 5 min | audit only |

Total: ~40 minutes. Steps 1-3 are the high-impact visual fixes. Steps 4-5 are
player performance. Steps 6-7 are polish.

---

## What this does NOT address (deferred)

- **High-contrast theme** — A pure black/white theme for maximum outdoor readability.
  Worth adding later as a 4th theme option.
- **Portrait orientation** — All layouts assume 16:9 landscape. Portrait (9:16)
  displays need different layouts with `aspect-ratio: 9/16`.
- **Day/night auto-switching** — Automatically swap theme based on time of day
  (dark during day for contrast, light at night to avoid glare). Requires the
  day-parting/scheduling system.
- **Font loading** — Currently using system fonts. A custom brand font would need
  `@font-face` with `font-display: block` to prevent FOIT on the player.
