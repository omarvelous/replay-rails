# Signage CSS

Ads render at any resolution — from a 400px preview card in the app to a full 1920px TV screen — using CSS container queries instead of media queries.

## Container query approach

The `.ad-canvas` wrapper sets `container-type: inline-size`. All typography and spacing use `cqw` (container query width) units via CSS custom properties:

```css
.ad-canvas {
  container-type: inline-size;
  --s-base: 1.8cqw;
  --s-hero: 7cqw;
  --s-pad: 5cqw;
  --s-qr: 8cqw;
  --s-avatar: 15cqw;
}
```

`1cqw` = 1% of the container's width. On a 1920px screen, `--s-base: 1.8cqw` = ~35px. On a 400px preview, the same token = ~7px. Everything scales proportionally.

## Why not media queries

Media queries respond to the viewport. But the same ad renders in multiple contexts:

| Context | Container width |
|---------|----------------|
| Player slideshow on TV | 1920px |
| Ad preview in app | ~400px card |
| Full preview page | ~1200px |
| Admin dashboard | ~300px thumbnail |

With `cqw` units, the ad scales correctly in all of these without any breakpoint logic.

## Custom properties

| Token | Value | Used for |
|-------|-------|----------|
| `--s-base` | `1.8cqw` | Body text |
| `--s-hero` | `7cqw` | Hero headlines |
| `--s-pad` | `5cqw` | Content padding |
| `--s-qr` | `8cqw` | QR code badge size |
| `--s-avatar` | `15cqw` | Agent photo size |

Layout partials reference these tokens for consistent scaling across ad types.

## Theme custom properties

Color themes are applied via inline CSS that overrides these properties:

| Property | Purpose |
|----------|---------|
| `--ad-bg` | Background color |
| `--ad-text` | Primary text color |
| `--ad-text-muted` | Secondary text color |
| `--ad-accent` | Accent/highlight color |
| `--ad-surface` | Card/overlay surface color |

The `ad_theme_style(theme)` helper generates the inline `style` attribute based on the theme name (`dark`, `light`, `brand`).

## Layout rendering

Each ad renders through two layers:

1. **Layout partial** (`app/views/app/ads/layouts/_hero.html.erb`, etc.) — controls the overall structure (full-bleed image, split pane, centered, grid)
2. **Content partial** (`app/views/app/ads/listing_ads/_content.html.erb`, etc.) — type-specific details (property stats, agent info, brand copy)

The layout wraps everything in `.ad-canvas` which establishes the container query context.

## Performance

- No JavaScript for sizing — pure CSS
- No layout shifts — container queries resolve on first paint
- Images use `object-fit: cover` for consistent framing
- Gradient overlays use CSS gradients (no image assets)
- QR codes render as inline SVG (no image requests)

## Player layout

The player layout (`layouts/player.html.erb`) is minimal: black background, no chrome, `overflow: hidden`. The slideshow fills the viewport and transitions between slides using opacity crossfade.
