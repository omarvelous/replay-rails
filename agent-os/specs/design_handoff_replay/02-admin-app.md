# 02 — Admin Application

The manager-facing platform. Sidebar + topbar shell, 13 routes, two full-bleed builders.

---

## Shell

### Sidebar — 248px, fixed, dark

Top to bottom:
1. **Logo** — a rounded blue-gradient mark containing a white play triangle, plus the wordmark "Re**Play**" (the second half in `--blue`, or `#7aa2ff` on dark).
2. **Account switcher** — "VR" square mark, "Vantage Realty", "Enterprise · 5 sites", chevron.
3. **Grouped nav** — each group has an uppercase micro-label:
   - **Overview** — Dashboard, Analytics
   - **Network** — Sites, Screens, Players
   - **Content** — Listings, Ads, Campaigns, Playlists
4. **Bottom** — Settings, then the signed-in user (avatar "MC", "Maya Chen", "Office Manager", overflow dots).

Nav items carry inline status: Screens shows a count pill (`10`); Players shows a small amber warning dot when a device is offline. This is deliberate — the network's health is visible from anywhere in the app.

**Active-section resolution.** The highlighted nav item is not always the raw route. Aliases:
- `ad-builder` → highlights **Ads**
- `playlist-builder` → highlights **Playlists**
- any `listing-*` route → highlights **Listings**

Preserve this pattern for any future sub-route.

### Topbar — 60px

Left: page title + optional subtitle. Right, in order:
- **Search affordance** — a fake input reading "Search or jump to…" with a `⌘K` key hint. Clicking it opens the command palette.
- Optional per-page actions.
- **`+ Create` menu** — a dropdown with five entries, each a label + one-line description: Create an ad · Add a listing · Build a playlist · New campaign · Register a device. Closes on outside pointerdown.
- **Notifications** bell with a count badge (3).
- **Publish** primary button with a pending-count pill (`Publish 2`). Opens the publish modal.

### Command palette (⌘K)

Full-screen scrim with a centered panel. Autofocused input, filtered list, `esc` hint. 13 targets: four quick-create **Actions** and nine **Go to · {group}** page jumps, each with an icon, a label, and a right-aligned kind label. Enter activates the first result; Escape closes.

### Full-bleed routes

`ad-builder` and `playlist-builder` hide the topbar and render edge to edge. Everything else renders inside the standard scrolling content area under the topbar.

### Tweaks panel

A prototype-only affordance exposing three live options — accent color (blue / teal / violet / amber), density (comfortable / compact), corners (rounded / sharp) — applied by rewriting `:root` custom properties. Useful as evidence the token system supports theming; **not** a feature to ship as-is.

---

## Route map

| Route | Screen | Type |
|---|---|---|
| `dashboard` | Dashboard | Standard |
| `analytics` | Analytics | Standard |
| `sites` | Sites | Standard + modal + drawer |
| `screens` | Screens | Standard + drawer |
| `players` | Players | Standard + modal + drawer |
| `listings` | Listings | Standard + modal |
| `listing-<id>` | Listing detail | Standard (dynamic) |
| `ads` | Ads index | Standard |
| `ad-builder` | Ad Builder | **Full-bleed** |
| `campaigns` | Campaigns | Standard |
| `playlists` | Playlists index | Standard |
| `playlist-builder` | Playlist Builder | **Full-bleed** |
| `settings` | Settings | Standard + modal |

---

## Dashboard

**Purpose:** answer one question on open — *is everything running, and is it working?*

Vertical stack:

**1. Setup checklist** (dismissible, hidden once complete) — a blue-gradient card with a white progress donut (`3/5`) and five step chips: Connect your first site ✓ · Pair a player device ✓ · Add listings from MLS ✓ · Build your first playlist · Publish to a screen. Completed steps show a check; pending steps show their number and are clickable. A ✕ dismisses the whole card.

**2. Quick actions row** — four wide buttons, each a tinted icon tile + title + one-line description + chevron: Create an ad (blue) · Build a playlist (teal) · Add a screen (violet) · View analytics (amber).

**3. KPI strip** — five `StatCard`s: Sites `5` (+1) · Active screens `14` (93%) · Online players `13/14` · Active campaigns `3` · QR scans today `1,840` (+21%).

**4. Two-column body** (`1.6fr / 1fr`, `align-items: start`)

*Left:*
- **QR scans chart** — card header with a 12M/30D/7D segmented control. Inside: `12,840` at 34px with a green "+34% vs last yr" delta pill, then a 150px bar chart across 12 months. All bars `--surface-3` except the current month, which uses the blue→teal vertical gradient. Bars have a 5px top radius and a `{n} scans` tooltip.
- **Top performing ads** — table with a numbered rank chip, ad name, campaign, mono scan count, and a scan-through bar (64px track, blue→teal gradient fill) plus its percentage.

*Right:*
- **Network health** — a 93% green donut beside three legend rows (Online players 13 · Offline 1 · Unassigned screens 1), each a colored dot + label + mono value. Full-width `Inspect players` button below.
- **Recent activity** — feed rows: a colored dot (halo'd with a 3px alpha ring, color by event kind), then "**{who}** {action} **{object}**" and a relative timestamp. Kinds: publish (blue), alert (red), create (teal), schedule (violet), metric (green), rollback (amber).

---

## Sites

Cards ⇄ Map toggle.

**Card view** — 3-column grid. Each card: a 124px tinted placeholder header with a type badge top-left and an "N/M live" badge top-right (green when all online, amber otherwise), then the site name, address with a pin icon, and a three-up `MiniStat` footer (Screens · Online · Scans) above a hairline divider. A dashed "Add a site" tile closes the grid.

**Map view** — an abstract grid-lined canvas with a pin per site positioned by percentage coordinates. Each pin is a colored dot containing its screen count; the color goes amber if any screen is offline. Hovering a pin fills a floating info card (type badge, name, address, the same three MiniStats).

**New site modal** — two-step create flow.

**Site detail** — a right slide-over: 170px tinted photo header with a type badge and close button, then the site name, address, a three-up StatCard row (Screens · Online · Scans this month), and a list of that site's screens (thumbnail, name, playlist, status badge). Footer: `Manage screens` · `Edit playlist`.

---

## Screens

Grid ⇄ Table. Filters: All · Live · Issues, plus Site and Orientation filter chips and a search field.

**Grid view** — 4-column. Each tile:
- A **live preview** of what that screen is actually playing right now, rendered by the `ScreenContent` component (see below), with a status badge overlay and a selection checkbox.
- Below: screen name + orientation badge, site name, playlist row, and a heartbeat row with a wifi / wifi-off icon colored green or red — "Heartbeat 12s ago", "Offline · 2h ago", or "No player assigned".
- A full-width **`Change content`** button opening an in-place popover listing every playlist, with a check beside the current one. The card must keep `overflow: visible` and lift on `z-index` while the popover is open.
- Clicking the preview or the name opens the **screen detail drawer** (see `03-detail-views.md`).

**Table view** — checkbox column, screen (48×30 live mini-preview + name), site, player (mono), playlist, status badge, heartbeat (mono), overflow. Rows open the drawer.

**Bulk action bar** — appears fixed at the bottom when any row is selected: "N selected" · Assign playlist · Restart · Publish · Clear.

### `ScreenContent` — the live preview renderer

Reused in the grid, the table, and both drawers. Takes a screen and a `mini` flag, and renders what that screen is showing:
- `idle` → an em-dash on dark
- `offline` → a wifi-off glyph on `#0b0d12`
- otherwise → a creative variant chosen by playlist: `HeroMini` (price + address over a dark tinted gradient, with an eyebrow and a white QR square), `OpenMini` (blue→teal gradient, "OPEN HOUSE / Sat 2–4PM"), or `BrandMini` (gradient mark + "Vantage" on near-black).

Every dimension in these minis scales off the `mini` flag, so the same component reads correctly at 48×30 and at 320×180. **This is the component to get right first** — it appears in more places than any other.

---

## Players

Table-first, because the failure mode is what matters.

**Offline alert banner** above the table: red-soft background, wifi-off icon, "**Signage Stick · B2** at Williamsburg Leasing went offline 2 hours ago. The Corner Display is currently dark." and a `Troubleshoot` button that opens the offline device's drawer directly.

**Table** — device (hardware-tinted icon tile + mono name), hardware, site, assigned screen, version (amber with a `↑` when behind), uptime, status badge, overflow. Rows open the **player detail drawer** (see `03-detail-views.md`).

**Register device modal** — a guided two-step pairing flow, not a config form:
1. Pick hardware from three cards, each with a tinted icon and a one-line setup hint ("Install the RePlay app from the Appstore" / "Ships pre-loaded — just power on" / "Flash RePlay OS to the SD card").
2. A 6-digit pairing code shown as three large mono chips (`R7 K2 9X`) with a spinner and "Waiting for device to connect…". After ~2.6s it flips to a success state: green check circle, "FireStick-4K · A5 connected", "Running RePlay v2.8.1 · Assign it to a screen next." Footer gains an `Assign to screen` button.

---

## Listings

Gallery ⇄ Table, filtered by area. Cards show the property placeholder, status badge, price, address, and a bed/bath/sqft spec row, with a `Use in ad` button.

Clicking a card or row opens the **listing detail page**; the header `New listing` button opens the **listing editor**. Both are fully specified in `03-detail-views.md`.

---

## Ads (index)

Grid ⇄ Table. Filters: All · Live · Scheduled · Drafts, plus a Campaign filter and search.

**Grid** — 3-column. Each card's media area is a 16:9 dark gradient tinted by the ad's tone, rendered with a type-appropriate mini creative (`AdThumbBody`: Open House → "OPEN HOUSE / Sat 2–4PM"; Recruiting → "WE'RE HIRING / Join our team"; Branding → "Vantage Realty / #1 in Brooklyn"; otherwise a listing hero with a "FOR SALE" eyebrow, price, and a white QR square). Body: name + type badge, campaign, then a spec row with scans, scan-through %, and the updated date. A dashed "New ad — Start from a template" tile closes the grid.

**Table** — ad (54×32 gradient thumb + name), campaign, type badge, status, mono scans, scan-through, updated, and a duplicate action.

Anything clickable opens the Ad Builder.

> **Why index-first:** marketing managers manage a *library* — duplicating winners, checking scan-through, spotting drafts — far more often than they build from scratch. The builder is one click in.

---

## Ad Builder (full-bleed)

A Canva-style editor. Three regions under a builder topbar.

**Builder topbar** — back chevron to the Ads index, the ad's name and its campaign + status, then `Duplicate` · `Preview` · `Publish ad`.

**Left rail**
- **Start from a template** — a 2×2 grid of template chips (Just Listed, Open House, Price Drop, Recruiting), each a small gradient thumbnail. Picking one applies a preset of layout + theme + headline + CTA in a single click.
- **Layout** — four chips, each with a tiny abstract wireframe thumbnail: Hero, Split, Minimal, Stat.
- **Theme** — three swatch dots: dark, light, brand (blue→teal gradient).
- **Media** — a photo placeholder plus `Replace media`.

**Center canvas** — the live `AdPreview` at 16:9, on a neutral stage, with a footer reading `16:9 · 1920×1080` and "Live preview — edits apply instantly."

**Right rail**
- **Content** — Headline, Subheadline, Call to action.
- **Linked listing** — a select of every listing, formatted "{address} — {price}". Choosing one **auto-fills the price and the bed/bath/sqft spec line** from the listing record.
- **Price** override field.
- A QR explainer panel: a small rendered QR glyph beside "A tracked **QR code** is auto-generated and links to this listing's mobile page."

### `AdPreview` — the four layouts

All four are absolutely-positioned, `overflow: hidden`, themed by a `{bg, fg, accent, sub}` object, and sized entirely in `cqw` units so they scale to any frame.

| Layout | Composition |
|---|---|
| **Hero** (default) | Full-bleed photo at 32% opacity (50% on light), a bottom-up scrim gradient, and a bottom row: eyebrow "JUST LISTED" in accent, 4cqw headline, subhead, then price (3.4cqw) + specs. QR block right-aligned with the CTA beneath it. |
| **Split** | 48% photo left; right side vertically centered with eyebrow, 3.4cqw headline, subhead, price, specs, then an inline QR + CTA row. |
| **Minimal** | Centered stack: "VANTAGE REALTY" eyebrow, 4.4cqw headline capped at 16ch, subhead capped at 34ch, QR, CTA. |
| **Stat** | Photo fills the upper area; bottom row pairs a 3cqw headline + price/specs against a right-aligned QR. |

The themes: **dark** (`linear-gradient(135deg,#0b0d12,#1c2230)`, white text, `#5b9bff` accent) · **light** (`#f7f8fa`, ink text, `--blue` accent) · **brand** (`linear-gradient(135deg,#1f54e0,#0fb5a6)`, white text and accent).

The QR is a CSS-grid fake — a 5×5 pattern of dark cells on white, sized as a percentage of the frame. Replace with real generated QR codes.

---

## Campaigns

A Gantt-style schedule timeline showing each campaign as a colored bar across a date axis, plus campaign cards carrying performance figures.

---

## Playlists (index)

Row-based. Each row: a blue playlist icon tile, a fixed 210px name + site block, then a flexible **mini loop timeline** — a segmented bar where each slide's width is proportional to its duration, colored by slide tone — with "N slides · M:SS loop" beneath. Right side: a Screens MiniStat, a status badge ("v6 live" green / "Draft" amber), the updated date, and an overflow button.

Filters: All · Published · Drafts. Rows open the builder.

> **Why index-first:** the daily question is "what's scheduled where, and is it live?" — answered by site, screen count, and publish status, with the loop strip previewing pacing at a glance.

---

## Playlist Builder (full-bleed)

A Spotify-style queue editor. Two columns (`1fr / 380px`) under a builder topbar.

**Builder topbar** — back chevron, playlist icon tile, name + "Assigned to 2 screens · Published v6", then the total loop length in mono with a clock icon, `Preview loop`, and `Publish`.

**Left — sequence**
- **Loop timeline** — a proportional ruler: one segment per slide, width = duration ÷ total, colored by slide tone, labeled with the slide type when the segment is wide enough. Clicking a segment selects that slide. Header shows "N slides · M:SS".
- **Sequence list** — draggable rows, each with a grip, mono index, a thumbnail, name + type, an inline duration stepper (`−` / `0:12` / `+`, clamped 3–60s), and a remove ✕. The selected row is filled `--blue-soft`. Drag-over shows an insertion state; dropping reorders.
- A full-width `Add content from library` button.

**Right — preview panel**
- A 16:9 live preview of the selected slide (its own container-query context), a transport row (play button, progress bar, `0:05 / 0:12`), then **Slide settings**: Type select, read-only Duration, and Transition (Crossfade / Cut / Slide).
- Footer note: "Changes save to a draft — publish to push live."

### Content library modal

Opened by `Add content from library`. A 680px modal, `min(620px, 86vh)` tall, flex column.

- **Header** — title, "Pick existing ads, generate a hero from a listing, or drop in a slide template.", then a segmented control with counts — Ads (non-draft) · Listings · Slide templates — beside a search input.
- **Body** — a card grid. Each card: a gradient thumbnail with a type-appropriate mini creative, a selection check circle (filled blue when picked), an "In playlist" tag when that item is already in the sequence, then the name, a type badge, and its mono duration. Multi-select. Empty state: "No matches for '{query}'".
- **Footer** — left: "N selected · +0:MM to loop" (or "Select items to add"); right: `Cancel` and `Add N to playlist`, disabled until something is picked.

Listings become "{address} — Hero" slides at 12s; ads carry their own natural duration (branding 6s, open house 10s, otherwise 12s); templates cover Hook, Browse grid, Open house, Branding, Recruiting, CTA.

> **Why a list, not a calendar:** a playlist is an *ordered loop*, so sequence and pacing matter more than wall-clock time. It's the mental model of a music queue, which everyone already has.

---

## Analytics

Six tabs: Overview · Sites · Screens · Ads · Campaigns · QR Scans. Header shows "Last 30 days · updated 6m ago" with a date-range chip and an `Export` button.

**Overview / QR tabs**
- Four StatCards, each with a sparkline: QR scans `12,840` (+34%) · Unique scanners `9,210` (+28%) · Avg dwell `2:14` (+11%) · Scan-through rate `14.2%` (−2%).
- **Engagement trend** (`1.5fr`) — a 200px area chart: blue line at 2.4px, a vertical gradient fill fading to transparent, five horizontal gridlines, and a white-ringed dot on the final point.
- **Scans by site** (`1fr`) — ranked rows, each a name + mono value over a bar filled in that site's own color.
- **Foot-traffic heatmap** — a 7-day × 7-hour grid (Mon–Sun × 8a–8p in 2h steps) of rounded cells filled `rgba(47,107,255, 0.08 + v*0.85)`, weighted so weekends and midday run hot. Below: a Less→More legend of five swatches and "Peak: **Sat 2–4PM**" right-aligned. This is the panel that drives scheduling decisions.
- **Top performing ads** — the ranked table again, compact.

**Sites / Screens / Ads / Campaigns tabs** — a single ranked-bar card: numbered rank, name, mono value, and an 8px bar in the entity's color, sorted descending.

---

## Settings

Max 900px wide, with a 180px sticky sub-nav beside the content.

**Branding** — Logo & identity card: a 90px logo placeholder, `Upload logo` with the hint "SVG or PNG, min 512px. Shown on branding ads & QR pages.", the brokerage name field, and a brand-color row of four 42px swatches plus a dashed add button.
> Branding cascades to every screen and mobile page — set once, inherited by all ads.

**Team & Roles** — a member table: avatar + name + email, an inline role select, overflow. Five seeded members across Office Manager, Marketing Manager, Leasing Manager, Sales Gallery Manager, and Viewer. An `Invite` button sits in the card header.
> Roles map to real jobs, not abstract permissions — a Leasing Manager edits their site's playlists but can't touch billing.

**Billing** *(placeholder)* — plan card: "Enterprise", "16 screens · billed annually", an Active badge, and three MiniStats (Screens used 16/25 · Next invoice $1,840 · Renews Jan 2027).

**API & Devices** *(placeholder)* — a masked key row (`rp_live_••••••••••••••••3a9f`) with `Reveal` and `Rotate`.

### Publish modal

Opened from the topbar Publish button. Two segmented views.

**Review & publish** — a state chain (`Draft` badge → chevron → `Will publish as v7`), then a bordered three-row summary, each with a green check: "3 slides changed / Maple Ave hero, open house, brand timing" · "14 screens affected / Across Bushwick & Williamsburg" · "Safe to roll back / Previous version kept for 90 days". Below, a version-note field. Footer: `Keep as draft` · `Publish to 14 screens`.

On publish, the body swaps to a success state: green check circle, "Published to 14 screens", "Changes are now live across all assigned displays. v7 is the active version."

**Version history** — a vertical timeline: a dot per version (green and solid for the live one, hollow otherwise) connected by a 2px rail, with the mono version number, a Live badge where applicable, a relative timestamp, the change note, the author, and a `Restore this version` button on every non-live entry.
