# 01 — Design System

Source of truth: `source/assets/replay.css`. Every color, radius, and shadow below is a CSS custom property defined there. **Use the tokens, never raw hex**, so the accent-swap tweak and any future theming keep working.

---

## Color

### Foundation — cool-tinted neutrals

The neutral ramp is deliberately blue-tinted rather than pure gray. This is what makes the product read as "premium software" rather than "enterprise CMS," and it's the single most important thing to preserve when porting.

| Token | Value | Use |
|---|---|---|
| `--ink-900` | `#0b0d12` | Near-black foundation; primary text, dark surfaces |
| `--ink-800` | `#14171f` | Headings on light, hover text |
| `--ink-700` | `#1c2029` | Body copy |
| `--ink-600` | `#2a2f3a` | — |
| `--ink-500` | `#3b414e` | Muted on dark |
| `--slate-500` | `#5b6470` | Secondary text |
| `--slate-400` | `#8a929e` | Tertiary text, captions, icon defaults |
| `--slate-300` | — | Hover borders, disabled glyphs |
| `--surface` | `#fff` | Cards, modals, drawers |
| `--surface-2` | `#f7f8fa` | App background, inset panels, hover fills |
| `--surface-3` | — | Chart tracks, meter tracks, numbered chips |
| `--line` | `#e6e8ec` | Hairline borders |
| `--line-2` | — | Lighter internal dividers (rows within a card) |

### Dual accent

| Token | Value | Use |
|---|---|---|
| `--blue` | `#2f6bff` | **Primary accent** — active nav, primary buttons, focus, charts |
| `--blue-strong` | `#1f54e0` | Accent text on light backgrounds, active tab labels |
| `--blue-soft` | `#eaf0ff` | Icon tiles, active chips, selected rows |
| `--teal` | `#0fb5a6` | **Secondary accent** — gradient partner, second data series |
| `--teal-strong` / `--teal-soft` | — | Same pattern as blue |

Blue and teal together (`linear-gradient(135deg, #1f54e0, #0fb5a6)` or `90deg` for bars) is the signature brand gradient. Use it sparingly — logo mark, the current month's bar in the scans chart, scan-through progress bars, brand-themed ads.

### Semantic

| Token | Value | Meaning |
|---|---|---|
| `--green` / `--green-soft` | `#1f9d57` | Live, online, healthy, success |
| `--amber` / `--amber-soft` | `#e8990f` | Draft, pending, warning, stale firmware |
| `--red` / `--red-soft` | `#e5484d` | Offline, error, destructive |

### Data-viz extras

`#7c5cff` (violet) and `#e8990f` (amber) join blue, teal, green, and red as the chart palette. Site colors are per-site: `#2f6bff`, `#0fb5a6`, `#7c5cff`, `#e8990f`, `#e5484d`.

Hardware tones for device icons: Amazon Fire TV Stick 4K `#ff9900` · RePlay Signage Stick `#2f6bff` · Raspberry Pi 4 `#c51a4a` · fallback `#5b6470`.

---

## Typography

**Sans** (`--sans`): system stack — `-apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, Arial`.
**Mono** (`--mono`): SF Mono / JetBrains Mono stack. Used for **all** numerals in tables and stats, plus versions, IDs, IPs, MLS numbers, durations, and timestamps.

### Scale classes

| Class | Size | Use |
|---|---|---|
| `.t-display` | 40px | Hero numbers |
| `.t-h1` | 28px | — |
| `.t-h2` | 21px | Drawer titles |
| `.t-h3` | 16px | Card titles |
| `.t-body` | 14px | Body copy |
| `.t-sm` | 13px | Dense UI text |
| `.t-xs` | 12px | Captions |
| `.t-label` | 11px uppercase | Eyebrows |

Utilities: `.mono`, `.tabular` (tabular figures — required on any number that changes), `.muted` (`--slate-500`), `.faint` (`--slate-400`), `.cell-strong` (table-cell emphasis).

### Applied scale

| Role | Size / weight / tracking |
|---|---|
| Big stat / chart headline | 30–34px / 700 / -0.02em |
| Drawer title | 21px / 700 / -0.02em |
| Page `h2` | 20px / 700 / -0.02em |
| Spec value, billing plan | 20–24px / 700 / -0.02em |
| Card title `h3` | 15–16px / 650 / -0.01em |
| Section `h3` (drawer) | 13.5px / 650 |
| Body copy | 14px / 1.65 line-height |
| Row label + value | 13.5px (label 400 `--slate-500`, value 600 `--ink-900`) |
| Meta / caption | 12–12.5px `--slate-400` |
| Eyebrow (`.bld-sec-t`, `.le-sec`) | 11px / 650 / uppercase / 0.06em |
| Mono values | 12.5px |
| Micro labels (under stats) | 11px `--slate-400` |

Headings tighten tracking as they grow (-0.01em at 15px, -0.02em at 20px+, -0.025em on large ad headlines). Body copy uses `text-wrap: pretty`.

---

## Spacing, radius, shadow, layout

**Spacing scale (px):** 4 · 6 · 8 · 10 · 12 · 14 · 16 · 18 · 20 · 22 · 24 · 28.
Card padding 18–22px · page gutters 24px · grid gaps 10–20px · row padding 9–14px.

**Radius:** `--r-xs 6` · `--r-sm` · `--r-md` (cards, rows, tiles, inputs) · `--r-lg` · `--r-xl` (modals) · `--r-pill 999` (badges, chips, meter tracks).

**Shadow:** `--sh-xs` · `--sh-sm` · `--sh-md` · `--sh-lg` · `--sh-pop` (modals, drawers, popovers).
*(Note: `--sh-1` does not exist — an earlier draft referenced it and silently rendered no shadow.)*

**Layout:** `--sidebar-w 248px` · `--topbar-h 60px`.

---

## Base components (CSS classes in `replay.css`)

| Class | Notes |
|---|---|
| `.btn` | Variants `-primary` `-secondary` `-ghost` `-danger`, sizes `-sm` `-lg`, and `-icon` for square icon-only. Icon + label are flex with a gap. Disabled = 50% opacity, `pointer-events: none`. |
| `.field` / `.input` / `.select` / `.textarea` | `.field` is a flex column with a 6px gap; its `label` is 12.5px / 600 / `--ink-800`. |
| `.search` | Input with a leading search icon. |
| `.card` / `.card-pad` | `.card` is the surface + border + radius; `.card-pad` adds internal padding. `.ch` is the card header row (title left, link or control right); `.ch-link` is the right-hand text action. |
| `.badge` | Color variants `-green -red -amber -blue -teal -gray`; `.dot` adds a leading status dot; `.pulse` animates it. |
| `.tbl` / `.tbl-wrap` | Styled table. `.cell-strong` for the primary cell. |
| `.chip` | Filter pill; `.on` for active. |
| `.seg` / `.seg-btn` | Segmented control; `.on` for active. |
| `.bar` | Thin progress track with a `span` fill. |
| `.ph` | **Media placeholder** — see below. |
| `.page` / `.page-grid` / `.ph-head` / `.ph-actions` / `.toolbar` | Page scaffolding: content wrapper, grid, header row (title block left, actions right), and the filter toolbar. |
| `.card-grid` | Responsive card grid; callers set `gridTemplateColumns`. |

---

## Shared React components

Defined in `source/admin/js/shell.jsx` unless noted.

| Component | Purpose |
|---|---|
| `<Icon name size sw>` | The whole icon set — one component, 24px stroke paths, `currentColor`. Defined in `js/icons.jsx`. |
| `<Sidebar route go>` | Fixed 248px nav. Dark surface, logo, account switcher, grouped nav, settings + user at the bottom. |
| `<Topbar title sub actions onPublish onSearch go pending>` | Page title/subtitle, ⌘K search affordance, global `+ Create` menu, notifications, and the Publish button with a pending-count pill. |
| `<CommandPalette open onClose go>` | ⌘K overlay. 13 targets: 4 quick-create actions + 9 page jumps. Filters as you type; Enter selects the first result; Escape closes. |
| `<Segmented options value onChange>` | View toggles (Grid/Table, Cards/Map). |
| `<Badge status>` | Maps a status string to a color variant, a label, and whether to show a dot. Handles: live, online, offline, idle, draft, published, scheduled, paused, Active, For Rent, Pending. |
| `<StatCard label value delta deltaDir icon accent spark>` | The KPI tile. Optional delta pill and inline sparkline. |
| `<Sparkline data color h>` | Inline trend line. |
| `<AreaChart data h>` | Filled area chart with a gradient fill, gridlines, and an end-point dot (in `screens-analytics.jsx`). |
| `<Donut value size stroke color track label sub>` | Ring progress. |
| `<Avatar name color>` | Initials avatar. |
| `<Note>` | **Design-rationale callout.** See below. |
| `<PageGrid>` | Grid wrapper. |
| `<MiniStat label val color>` | Small mono value over an 11px label (in `screens-sites.jsx`). |
| `<Drawer children onClose width>` | Right slide-over shell (in `screens-detail-drawers.jsx`). See `03-detail-views.md`. |

### About `<Note>`

Most admin screens open with a `<Note>` explaining *why the screen is designed the way it is* — e.g. "Screens = the physical displays. Non-technical managers can't picture a screen from a row of text, so the default grid shows a live thumbnail of what's actually playing."

**These are annotations for the design review, not product copy.** Read them — they carry the reasoning behind each layout decision and are the best explanation of intent in the whole package. Then **do not ship them.** Drop them, or replace them with real empty-state and onboarding copy.

---

## Imagery convention — important

**Never draw photographs, and never hand-author illustrative SVG.**

Every image in every prototype is a placeholder: `<div class="ph" data-label="property photo">`. The `.ph` class renders a subtle striped block; `data-label` supplies a small mono caption naming what belongs there. Labels in use include `property photo`, `hero photo`, `kitchen`, `living`, `bedroom`, `exterior`, `location photo`, `logo`.

Placeholders are often tinted with the parent entity's `tone` color (e.g. `background: {listing.tone}1c`) so a grid of them still reads as visually varied.

When you implement, wire these to the real photo pipeline (MLS media, uploads). Do not substitute stock photography in the interim — a labeled placeholder communicates "real photo goes here"; a stock photo communicates "this is the design."

The one exception is **signage and ad creative**, which uses gradient tints over placeholders to suggest photographic backgrounds. Those gradients are part of the design and should be kept.

## Icons

A single inline 24px stroke set, `currentColor`, consistent stroke width, rendered through the one `Icon` component. Names in use:

`dashboard, analytics, sites, screens, players, listings, ads, campaigns, playlists, settings, qr, grid, list, plus, check, x, chevronR, chevronD, dots, upload, download, refresh, wifi, wifiOff, play, pause, clock, eye, bell, search, filter, calendar, layers, zap, link, map, building, arrowUp, arrowDown`

Swap these for the target codebase's icon library. **Match the weight and size, not the exact paths** — the visual consistency of a single-weight stroke set at 13–18px is what matters.

## Container queries

Signage frames, ad previews, and mobile screens set `container-type: size` and size their type in `cqw` / `cqh` units. This is what lets the same ad component render correctly at 1920×1080 on a real screen, at 640×360 on the playback board, and at 260px wide in a builder preview.

**Keep this.** Do not convert these to fixed px or viewport units — it breaks the multi-scale rendering that the entire signage system depends on.
