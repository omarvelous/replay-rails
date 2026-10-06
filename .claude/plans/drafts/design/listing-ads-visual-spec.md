# Listing Ad — Visual Spec

Layouts, themes, and type scale for single-listing ads on storefront screens. Design only.

---

## 0 · Ground rules (apply to every layout)

**Canvas.** Every ad is designed at the screen's real size: 1920×1080 (16:9) or 1080×1920 (9:16). All sizes below are in `cqw`, the width of the ad frame. Pixel equivalents are given for checking.

**Safe margin.** No text, QR code, badge, or agent strip sits inside this margin. Photos still bleed to the edge.
- 16:9: **3.2cqw** (61px)
- 9:16: **6cqw** (65px)

**Reading distance.** Designed to read from 20 ft through glass. Nothing readable goes below **1.0cqw landscape / 1.8cqw portrait** (about 19px either way).

**Hierarchy, in every layout:** price → address → specs → badge → QR → agent. Only one element is hero-sized: the price. For Open House, the date/time pill shares that top level.

**Brokerage mark.** Small wordmark, always in the top corner opposite the badge, at 1.3cqw / 2.6cqw. On a photo it sits on a `--ad-bg` chip so it stays legible.

**Photo scrim.** Wherever text sits on a photo, a gradient from `--ad-bg` fades the photo out under the text. It runs from 0% opacity to 85% over the text zone and never covers more than 55% of the photo.

**Photo crop.** Photos fill their box and crop to it, centered. Exteriors anchor the crop 40% from the top so rooflines survive.

---

## 1 · Layouts

Existing layouts are renamed to describe their structure. Five new layouts are recommended.

| Layout | Was | Photos | Best for |
|---|---|---|---|
| Overlay | hero | 1 | Default. Strong single exterior. |
| Split | split | 1 | Busy photos, long addresses. |
| Type + Photo | minimal | 0–1 | Weak or missing photos; Coming Soon. |
| Stat Grid | stat_grid | 1 | Spec-led listings (big lots, new builds). |
| Band *(new)* | — | 1 | Wide panoramic exteriors. |
| Card *(new)* | — | 1 | Busy photos where you still want full-bleed. |
| Mosaic *(new)* | — | 3 | Interiors sell the home. |
| Diptych *(new)* | — | 2 | Exterior + one signature interior. |
| Sequence *(new)* | — | 3 | Long loop slots; motion draws the eye. |

Fallbacks when photos are missing: Mosaic and Sequence fall back to Diptych if there are 2 photos, otherwise Overlay. Diptych falls back to Overlay. Any layout with 0 photos falls back to Type + Photo with no photo.

---

### Overlay *(was hero)* · 1 photo

**16:9**
- **Photo:** full-bleed, the whole frame.
- **Scrim:** bottom-left, rising to about 55% of the height.
- **Badge:** top-left at the safe margin.
- **Text:** bottom-left block, max width 58cqw. Badge → address → neighborhood line → specs line, stacked.
- **Price:** bottom-right, baseline-aligned with the address. The QR code sits directly to the right of it.
- **QR:** bottom-right corner, with a one-line CTA above it, right-aligned.
- **Agent strip:** top-right, below the brokerage mark, as a pill on `--ad-surface`.

**9:16**
- Photo stays full-bleed. The scrim covers the bottom 50%.
- The text stacks in the bottom half: badge → address → neighborhood → specs → price.
- The QR goes bottom-right, with the price bottom-left on the same baseline.
- The agent strip moves to top-left, under the badge.

---

### Split · 1 photo

**16:9**
- **Photo:** the left 58% of the frame, full height. No scrim.
- **Text column (right 42%):** `--ad-bg`, with content vertically centered and a 3.2cqw inset.
  - Top: badge.
  - Middle: address → neighborhood → specs as a **3-column grid** (big number, small caps label, thin rule between columns).
  - Then price, at full hero size.
  - Bottom row: QR on the left, CTA beside it.
- **Agent strip:** pinned to the bottom of the text column, above the QR row, with a top rule.

**9:16**
- The photo takes the top 52%. The text panel takes the bottom 48%.
- Same order of content. The spec grid stays 3 columns.
- The QR goes bottom-right and the agent strip bottom-left, side by side.

---

### Type + Photo *(was minimal)* · 0–1 photo

**16:9**
- **Photo (optional):** full-bleed under a heavy `--ad-bg` wash at 78% opacity. It reads as texture, not as a picture. With 0 photos, the wash is the plain background.
- **Text:** left-aligned, the full width minus the margins. The address is set large, at 5.2cqw / 600, and is the visual hero alongside the price.
- **Specs:** 3-column grid under the address.
- **Price:** bottom-left.
- **QR:** bottom-right, with the CTA to its left.
- **Badge:** top-left.
- **Agent strip:** bottom row, between the price and the QR.

**9:16**
- Same structure, stacked: badge at the top. The address, specs grid, and price sit centered vertically in the middle.
- The QR and agent strip share the bottom row.

---

### Stat Grid · 1 photo

The specs are the content: a 2×2 grid of large figures (beds, baths, sq ft, plus lot or year built).

**16:9**
- **Photo:** the right 40%, full height.
- **Left 60%:** badge → address at sub-hero size (3cqw) → the **2×2 stat grid**. Figures are 4.4cqw / 600 with labels at 1.0cqw in small caps; 1px rules divide the cells.
- **Price:** under the grid, at hero size.
- **QR:** bottom-left with the CTA.
- **Agent strip:** bottom-right of the text area.

**9:16**
- The photo takes the top 36%. The stat grid stays 2×2 below it, full width.
- The price follows. The QR and agent strip share the bottom row.

---

### Band *(new)* · 1 photo

**16:9**
- **Photo:** the top 68%, full width. No scrim.
- **Band:** the bottom 32%, a solid `--ad-bg` strip with one horizontal row of content: address + neighborhood (left) · specs inline (center-left) · price (center-right) · QR + CTA (right).
- **Badge:** on the photo, top-left.
- **Agent strip:** on the photo, top-right.

**9:16**
- The photo takes the top 58%. The band grows to 42% and stacks: address → specs → price, with the QR at bottom-right.
- The agent strip stays on the photo.

---

### Card *(new)* · 1 photo

**16:9**
- **Photo:** full-bleed. No scrim.
- **Card:** a floating `--ad-surface` panel, bottom-left, 46cqw wide, inset by the safe margin, with corner radius 0.8cqw.
- **Inside the card:** badge → address → neighborhood → specs as a 3-column grid → price.
- **QR:** outside the card, bottom-right, on its own white tile.
- **Agent strip:** at the top of the card, above the badge, as a small row. Or top-right on the photo if the card is too tall.

**9:16**
- The card goes full width (minus margins), bottom-anchored, and covers up to 50% of the height.
- The QR moves inside the card, bottom-right.

---

### Mosaic *(new)* · 3 photos

**16:9**
- **Photos:** the left 64%. One large photo (exterior) takes the left 2/3. Two stacked photos (interiors) take the right 1/3. Gutters are 0.4cqw in `--ad-bg`.
- **Text column (right 36%):** badge → address → neighborhood → specs inline → price → QR + CTA.
- **Agent strip:** bottom of the column.

**9:16**
- The photos take the top 55%: one large photo across the top, two side by side below it.
- The text takes the bottom 45%, in the same order. The QR goes bottom-right and the agent strip bottom-left.

---

### Diptych *(new)* · 2 photos

**16:9**
- **Photos:** two equal halves, edge to edge, with no gutter. Left is the exterior, right is an interior.
- **Text bar:** a centered `--ad-bg` bar that bridges the seam, 72cqw wide, anchored to the bottom margin. It holds: address + specs (left) · price (center) · QR (right).
- **Badge:** top-left on the left photo.
- **Agent strip:** top-right on the right photo.

**9:16**
- The photos stack, exterior on top and interior below, each 50% of the height.
- The text bar straddles the seam at the center, full width minus margins, in two rows: address/specs, then price + QR.
- The badge goes top-left and the agent strip bottom-left.

---

### Sequence *(new)* · 3 photos

- **Geometry:** identical to Overlay in both orientations.
- **Motion:** the photo crossfades through 3 photos across the ad's duration (equal thirds), with a slow 4% push-in on each.
- **Static elements:** text, price, QR, badge, and agent strip never move.
- **Progress ticks:** three thin ticks (2.4cqw × 0.2cqw) above the address show which photo is up.
- **Reduced motion:** straight crossfade with no push.

---

## 2 · Themes

Three themes, unchanged in name. Light is for daytime only: glare washes out dark text after dusk, and a white panel glows at night.

### Dark (default · any time of day)

| Token | Value | Use |
|---|---|---|
| `--ad-bg` | `#0B0D12` | Panels, bands, scrim base |
| `--ad-text` | `#FFFFFF` | Price, address, spec figures |
| `--ad-text-muted` | `rgba(255,255,255,0.72)` | Neighborhood line, CTA, agent phone |
| `--ad-text-faint` | `rgba(255,255,255,0.52)` | Spec labels, rules (at 0.20) |
| `--ad-accent` | `#5B9BFF` | Badge fill, progress ticks, price-drop delta |
| `--ad-surface` | `#161A22` | Card, agent pill, text bar |

The badge label sits on the accent in `#0B0D12`.

### Light (daytime only · 7am–7pm)

| Token | Value | Use |
|---|---|---|
| `--ad-bg` | `#F7F8FA` | Panels, bands, scrim base |
| `--ad-text` | `#0B0D12` | Price, address, spec figures |
| `--ad-text-muted` | `#5B6470` | Neighborhood line, CTA, agent phone |
| `--ad-text-faint` | `#6B7380` | Spec labels; rules at `rgba(11,13,18,0.12)` |
| `--ad-accent` | `#2F6BFF` | Badge fill, ticks, delta |
| `--ad-surface` | `#FFFFFF` | Card, agent pill, text bar |

The badge label sits on the accent in `#FFFFFF`. `--ad-text-faint` is set darker than usual on purpose so it still passes 4.5:1 on `--ad-bg`.

### Brand (per brokerage)

Derived from the brokerage's primary brand color (**P**). The example values below use P = `#1E3A5F`.

| Token | Rule | Example |
|---|---|---|
| `--ad-bg` | P, darkened until lightness is ≤ 22% | `#14273F` |
| `--ad-text` | White if bg is dark, else `#0B0D12` | `#FFFFFF` |
| `--ad-text-muted` | `--ad-text` at 72% | `rgba(255,255,255,0.72)` |
| `--ad-text-faint` | `--ad-text` at 52% | `rgba(255,255,255,0.52)` |
| `--ad-accent` | Brokerage secondary color; else P lightened to 70% | `#7FA8D9` |
| `--ad-surface` | `--ad-bg` lightened by 6% | `#1C3350` |

**Guardrails:**
- If the accent is under 3:1 against `--ad-bg`, use white for the accent and P for the badge label.
- Never use a brand color for the price. The price is always `--ad-text`.

### Shared across all themes
- **QR tile:** always `#FFFFFF`, with a quiet zone of 8% of the QR size and corner radius 6% of its size. The modules are always `#0B0D12`. Themes never recolor the QR.
- **Badge state colors** (any theme):
  - Under Contract: `#F2A516` with `#0B0D12` text
  - Sold / Coming Soon: `#0FB5A6` with `#0B0D12` text
  - Every other status uses `--ad-accent`.

---

## 3 · Typography

- **Typeface:** Inter Tight for everything. Tabular figures for price and specs.
- **Tracking:** display sizes (price, address) at −0.035em; small caps labels at +0.14em.
- **Columns:** 16:9 / 9:16. Pixel equivalents are at 1920 or 1080 wide.

| Role | 16:9 | 9:16 | Weight | Notes |
|---|---|---|---|---|
| **Price** (hero) | 5.6cqw · 108px | 11cqw · 119px | 600 | Line-height 1. `/mo` suffix at 40% size, 500. |
| **Address** (headline) | 3.4cqw · 65px | 7cqw · 76px | 600 | Line-height 0.96, max 2 lines, balanced wrap. Type + Photo raises it to 5.2 / 9.6cqw. |
| **Subheadline** (neighborhood · type) | 1.5cqw · 29px | 3.4cqw · 37px | 500 | `--ad-text-muted`. |
| **Specs line**, inline | 1.4cqw · 27px | 3.2cqw · 35px | 600 figures / 500 labels | Figures in `--ad-text`, labels in `--ad-text-faint`. Thin vertical rules between items. |
| **Specs**, grid figure | 2.4cqw · 46px | 5cqw · 54px | 600 | Split, Card, Type + Photo. |
| **Specs**, grid label | 1.0cqw · 19px | 2cqw · 22px | 600 caps +0.14em | `--ad-text-faint`. |
| **Badge label** | 1.1cqw · 21px | 2.4cqw · 26px | 600 caps +0.14em | Padding 0.6 / 1.0cqw (landscape), 1.2 / 2cqw (portrait). Radius 0.3cqw. |
| **Agent name** | 1.2cqw · 23px | 2.6cqw · 28px | 600 | `--ad-text`. |
| **Agent details** (phone, title) | 1.0cqw · 19px | 2.2cqw · 24px | 500 | `--ad-text-muted`. Avatar is 3.4cqw / 7cqw, circular. |
| **Open house pill**, date | 1.3cqw · 25px | 3cqw · 32px | 600 caps +0.08em | e.g. "SAT · MAY 18". |
| **Open house pill**, time | 2.4cqw · 46px | 5.4cqw · 58px | 600 | e.g. "12–3pm". |
| **QR CTA** | 1.0cqw · 19px | 2.2cqw · 24px | 500 | Max 2 lines, `--ad-text-muted`. |
| **Brokerage mark** | 1.3cqw · 25px | 2.6cqw · 28px | 600 | |

**QR size:** 6.5cqw (125px) landscape, 15cqw (162px) portrait. Never smaller. That size scans from about 1.5 m through glass.

**Open house pill:**
- Sits directly above the price. The price stays in its normal position at full size.
- The pill is a `--ad-surface` rounded rectangle (radius 0.6cqw), padded 0.8 / 1.4cqw landscape and 1.6 / 2.6cqw portrait.
- Date and time stack inside it, with a 3px `--ad-accent` bar on the leading edge.
- On a photo with no scrim (Card, Band), it uses `--ad-bg` instead of `--ad-surface`.

**Long-address rule:**
- Over 34 characters, step the address down 8% at a time, at most twice.
- If it still doesn't fit in 2 lines, truncate the neighborhood line instead. Never truncate the address.
