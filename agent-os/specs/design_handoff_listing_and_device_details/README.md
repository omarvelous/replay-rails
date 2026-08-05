# Handoff: RePlay — Listing Detail, Listing Editor, Screen & Player Detail Drawers

## Overview
Four connected pieces of the **RePlay** admin (a real-estate digital-signage SaaS):

1. **Listing detail page** — a full-page property record reachable from the Listings index.
2. **New / Edit listing modal** — one shared form serving both create and edit.
3. **Screen detail drawer** — a right-hand slide-over showing what a physical display is playing right now.
4. **Player detail drawer** — the same slide-over pattern for the device behind a screen, focused on connectivity and diagnostics.

Together they complete the "list → detail → edit" loop for the three core objects in the product: **listings** (content), **screens** (displays), and **players** (devices).

## About the Design Files
The files in this bundle are **design references created in HTML/JSX** — in-browser prototypes that demonstrate intended look, layout, and behavior. They are **not production code to copy directly**. They use no build step, in-browser Babel transpilation, `window`-globals for module sharing, and hardcoded mock data — all deliberate prototyping shortcuts.

Your task is to **recreate these designs in the target codebase's existing environment** (React, Vue, SwiftUI, native, etc.) using its established component library, routing, data layer, and styling conventions. If no environment exists yet, pick the framework most appropriate for the project and implement there.

## Fidelity
**High-fidelity.** Colors, typography, spacing, radii, shadows, interaction states, and copy are all final. Recreate pixel-accurately using the codebase's existing primitives. Every value below is exact.

---

## Screens / Views

### 1. Listing Detail Page

**Purpose:** An agent or marketing manager reviews a single property — its facts, photos, and how it is performing on signage — and jumps from here into ad creation or editing.

**Entry:** Clicking any card in the Listings gallery view, or any row in the Listings table view. Route pattern `listing-<id>` (e.g. `listing-l1`). The sidebar keeps **Listings** highlighted while on this route.

**Layout:** Standard content page inside the app shell (sidebar + topbar). Vertical stack:

| Order | Element | Notes |
|---|---|---|
| 1 | Back link | "← Listings", 13px / 600, `--slate-500`, hover `--ink-800`, 4px 0 padding, 8px bottom margin |
| 2 | Page header | Flex row, `align-items: flex-end`, `justify-content: space-between`, 16px gap, 20px bottom margin |
| 3 | Photo gallery | CSS grid, see below |
| 4 | Spec strip | Single card, horizontal, 20px bottom margin |
| 5 | Body grid | `grid-template-columns: minmax(0,1fr) 320px`, 20px gap, `align-items: start` |

**Page header**
- Left: address as `<h2>` (inherits page `h2`: 20px / 700 / -0.02em) with a status `Badge` beside it (12px gap, 4px bottom margin), then a subline: pin icon + `{neighborhood} · {type} · {MLS#}`. MLS number in monospace.
- Right (`.ph-actions`): `Edit listing` (secondary), `Use in ad` (primary, opens Ad Builder), and an icon-only overflow button (`…`).

**Photo gallery** — `.ld-gallery`
- `display: grid; grid-template-columns: 2.1fr 1fr 1fr; grid-template-rows: 1fr 1fr; gap: 10px; margin-bottom: 20px`
- Hero cell `.ld-hero`: `grid-column: 1; grid-row: span 2`. Contains a diagonal tint overlay `linear-gradient(150deg, {listing.tone}40, transparent 65%)`.
- 4 secondary cells, each `min-height: 122px`, `border-radius: var(--r-md)`, `overflow: hidden`, background `{listing.tone}1c`.
- Hero photo-count pill `.ld-count`: absolute 12px from left/bottom, grid icon + "12 photos", 12px / 600, white on `rgba(11,13,18,.62)`, 5px 10px, pill radius, `backdrop-filter: blur(4px)`.
- Last cell has a full-cover `+8 more` button `.ld-more`: `rgba(11,13,18,.42)` → `.55` on hover, white 13px / 650.
- **All photos are placeholders** (`<div class="ph" data-label="hero photo">` etc.). Never draw imagery in SVG. Labels used: `hero photo`, `kitchen`, `living`, `bedroom`, `exterior`.

**Spec strip** — `.ld-specs`
- A `.card` with `padding: 0`, `display: flex`, `overflow: hidden`.
- Five cells `.ld-spec`, each `flex: 1`, `padding: 18px 22px`, `border-left: 1px solid var(--line-2)` (none on the first).
- First cell `.ld-spec-price`: `flex: 1.3`, background `var(--surface-2)`, value 24px / 700 in `var(--blue-strong)`.
- Other values 20px / 700 / -0.02em with a 17px leading icon in `--slate-400`; labels 12px `--slate-400`, 4px top margin.
- Cells: **List price** (or "Asking rent" when price < 100000) · **Bedrooms** · **Bathrooms** · **Interior sq ft** · **Price / sq ft** (or "Lease term: 12 mo" for rentals).
- All numerals use the `tabular` class.
- Under 1080px: `flex-wrap: wrap`, each cell `flex: 1 0 33%`.

**Main column** (four stacked `.card.card-pad`, 18px gap)
1. **About this property** — 14px / 1.65 line-height, `--ink-700`, `text-wrap: pretty`. Uses `listing.desc` when the user has written one; otherwise falls back to a generated sentence pair built from beds/baths/type/sqft/neighborhood.
2. **Features & amenities** — `.ld-feat` wrap flex, 8px gap. Each chip: check icon (`--green`) + label, 12.5px / 550, `--ink-700`, `var(--surface-2)` bg, `1px solid var(--line-2)`, pill radius, `6px 12px`. The feature set is chosen by property type (see Data section).
3. **Property details** — 10 label/value rows `.ld-detail-row`: flex space-between, `11px 0`, `1px solid var(--line-2)` bottom border (last row none, no bottom padding), 13.5px. Label `--slate-500`; value 600 weight `--ink-900`. Rows: Property type, Status, Bedrooms, Bathrooms, Interior, Year built, Price per sq ft (or Lease term), Neighborhood, MLS # (mono), Days on market.
4. **Ads built from this listing** — section header row with a `View all →` ghost button. Populated state: rows `.ld-ad` (flex, 12px gap, `1px solid var(--line)`, `--r-md`, `9px 11px`, hover border `--slate-300` + `--surface-2` bg) containing a 64×40 thumbnail, name + "{layout} layout · {campaign}", right-aligned mono scan count, and a status Badge. Empty state `.ld-empty`: dashed border, 40px blue-soft icon tile, "No ads yet / Turn this listing into signage in one step." and a primary `Create ad` button.

**Sidebar column** (320px, 18px gap)
1. **Signage performance** — 30px / 700 tabular scan count + "QR scans · 30d" caption; a 38px-tall sparkline in `--blue`; then a 3-up footer row (18px gap, 14px top padding, `1px solid var(--line-2)` top border) with Scan-through %, Active ads, On screens — each a 16px mono value over an 11px `--slate-400` label.
2. **Listing agent** — avatar + name + "Vantage Realty", then two equal-width small secondary buttons: `Message`, `Profile`.
3. **Note** — "**Synced from MLS.** Property facts update automatically on the next sync — edits here only affect how the listing appears in RePlay signage."

Under 1080px the body grid collapses to a single column.

---

### 2. New / Edit Listing Modal (`ListingEditor`)

**Purpose:** Add an off-market property by hand, or correct an existing record. One component serves both; the only differences are the title, the intro copy, the MLS banner (create only), the prefilled values, and the submit label.

**Entry:** `New listing` button in the Listings page header (no id) · `Edit listing` button in the listing detail header (with id).

**Shell:** Centered modal over `.modal-bg`, `max-width: 680px` (`.modal-lg`). Body `.le-body` is `max-height: min(72vh, 600px)` with `overflow-y: auto`, so the header and footer stay fixed. Clicking the backdrop or the top-right ✕ closes.

**Header:** Title — "New listing" / "Edit listing". Sub — "Add a property manually, or sync your MLS to import in bulk." / "Update the property record used across RePlay signage."

**MLS banner** (create mode only) — `.le-mls`: refresh icon + "Connected to MLS — most listings import automatically. Use this form for off-market or pre-launch properties." + a small secondary `Sync MLS` button. Background `var(--blue-soft)`, border `1px solid #d9e4ff`, `--r-md`, `11px 13px`.

**Sections** — each preceded by a `.le-sec` eyebrow: 11px / 650 / uppercase / 0.06em tracking / `--slate-400`.

| Section | Fields |
|---|---|
| Property | Street address (full width, autofocus) · then a 3-column row (`.le-grid-3`, 14px gap): Neighborhood select, Type select, Status select |
| Pricing & size | Row 1: List price / Monthly rent (number, label switches on status) · Interior sq ft (number) · Year built (number). Row 2: Bedrooms (step 1) · Bathrooms (step 0.5) · MLS # (text, placeholder "auto") |
| Description | Textarea, 3 rows, placeholder "A few sentences buyers will see on the QR landing page…" |
| Features & amenities | Toggle chips `.le-chip` drawn from the pool for the currently-selected property type. Off: `--surface` bg, `1px solid var(--line)`, `--slate-500`, plus icon. On: `--blue-soft` bg, transparent border, `--blue-strong` text, check icon. First four preselected. |
| Photos | Dropzone `.le-drop`: 1.5px dashed border, `--surface-2` bg, upload icon, "Drag photos here or **browse**", caption "JPG or PNG · first image becomes the signage hero" |

**Footer:** `Cancel` (secondary) and `Create listing` / `Save changes` (primary).

**Validation:** Submit is disabled (50% opacity, `pointer-events: none`) until **address**, **price**, and **sq ft** are all non-empty. No other field is required — MLS # auto-generates as `RP-` + 5 random uppercase alphanumerics when left blank.

**Options:**
- Neighborhood: Bushwick, Williamsburg, Manhattan, Park Slope, Astoria, Greenpoint
- Type: Apartment, Condo, Co-op, Townhouse
- Status: Active, For Rent, Pending

**On save:**
- *Edit* — write the values back onto the record, force a re-render, close. The detail page reflects changes immediately.
- *Create* — generate an id, assign a `tone` by round-robin from the tone palette, default `dom: 0` / `lscans: 0` / a default agent, append to the collection, close, and **navigate straight to the new listing's detail page**.

---

### 3. Screen Detail Drawer (`ScreenDetail`)

**Purpose:** A manager checks one physical display — is it alive, what is it playing right now, and how is it performing.

**Entry:** Clicking the preview thumbnail or the name in a Screens grid tile, or a row in the Screens table. It is a **slide-over, not a route** — matching the existing Site detail pattern. Closes on backdrop click, the ✕, or the **Escape** key.

**Shell** — `.dw`: right-anchored, `width: min(580px, 100%)`, full viewport height, `--surface` bg, `var(--sh-pop)`, `slideIn .22s cubic-bezier(.2,.9,.3,1)` (translateX 40px + fade). Column layout: fixed hero → fixed head → **scrolling body** → fixed footer.

> **Critical layout constraint:** the drawer must be height-capped by the viewport so the body scrolls and the footer stays reachable. In the prototype this required zeroing the modal backdrop's padding, giving the backdrop grid `grid-template-rows: minmax(0,1fr)`, and setting `min-height: 0` on both the drawer and its scrolling body. Reproduce the equivalent constraint chain in whatever layout system you use — this was the single biggest bug found in review.

**Hero** — `.dw-hero`: dark `--ink-900` stage, 20px padding, `max-height: 32vh`, `overflow: hidden`. Inside, a bezel-framed live preview of the screen's current content:
- `.dw-bezel` — `border-radius: 6px`, layered outline shadows `0 0 0 5px #1c2029, 0 0 0 6px #2a2f3a, 0 18px 40px rgba(0,0,0,.5)`.
- The stage is **height-driven** so it never overflows the capped hero: landscape `height: 100%; width: auto; aspect-ratio: 16/9`; portrait `height: 100%; width: auto; aspect-ratio: 9/16`. Both also carry `max-width: 100%; max-height: 100%`.
- Status pill top-left `.dw-hero-tag`: "● Live now" (pulsing green dot), "Offline" (wifi-off icon), or "No content". White on `rgba(11,13,18,.6)`, blurred.
- The pulse dot: 7px green `#2fd97a` circle, `pulseDot 1.6s ease-out infinite` expanding a `rgba(47,217,122,.6)` ring out to 7px and fading.
- ✕ close button top-right on a `rgba(255,255,255,.9)` chip.

**Head** — `.dw-head`, `18px 24px 0`, bottom border. Screen name at 21px / 700 / -0.02em with a status Badge, then a subline: pin icon + `{site} · {orientation} · {display model}`. Below, a tab bar `.dw-tabs`: 13px / 600 buttons, `8px 12px`, `--slate-500`, active state `--blue-strong` with a 2px `--blue` bottom border.

**Tabs**

*Overview*
- Three `StatCard`s: **Scans (30d)** (amber), **Uptime** — 99.4% live / 82.1% otherwise (green or red), **Loop length** in seconds (blue).
- Conditional alert `.dw-alert` when not live. Offline: "Last heartbeat **{time}**. The display is dark — check power and network on **{player}**." + `Troubleshoot`. Idle/unpaired: "No player is paired to this screen, so nothing is playing. Register a device to bring it online." + `Pair device`. Red variant by default (`--red-soft` bg, `#f5c6c8` border, `#a3282c` text); a `.warn` variant uses `#fff6e5` / `#f2dcac` / `#8a5c00`.
- **Playing now** — one `.dw-card` row: blue-soft playlist icon tile, playlist name, "{n} items · {total}s loop", chevron. Clicking opens the Playlist Builder. Falls back to "No playlist assigned / Assign one to start playing".
- **Hardware** — `.dw-row` label/value list: Display, Orientation, Resolution (mono, 1920×1080 or 1080×1920), Player (mono), Firmware (mono; amber when not on the current version), Last heartbeat (mono), Site.

*Content*
- **Loop** — numbered rows: mono index, 58×36 thumbnail placeholder, item name + type, right-aligned mono duration. Empty state: "Nothing scheduled on this screen yet."
- **Schedule** — rows: Playing "Daily · 8:00 AM – 9:00 PM", Timezone "America/New_York", Overrides "None".

*Activity*
- "QR scans · last 14 days" + a 54px sparkline in `--blue`.
- **Event log** `.dw-log`: rows with a 7px status dot (`ok` green / `warn` amber / `bad` red), event text, right-aligned mono relative timestamp. Entries: heartbeat received or lost, playlist published, content swapped, player restarted, screen registered.

**Footer** — two equal buttons: `Change content` (secondary → Playlist Builder), `Restart screen` (primary).

---

### 4. Player Detail Drawer (`PlayerDetail`)

**Purpose:** The technical counterpart — diagnose a device that is offline, on stale firmware, or misbehaving.

**Entry:** Clicking any row in the Players table, or the `Troubleshoot` button in the offline alert banner at the top of the Players page (which opens the drawer directly on the offline device). Same slide-over shell, `width: min(560px, 100%)`.

**Hero** — `.dw-hero-dev`: light instead of dark. Background `linear-gradient(150deg, {hardwareTone}22, var(--surface-2))`, `min-height: 150px`, `max-height: 24vh`, 30px padding. Centered 72px white rounded-square (`border-radius: 18px`, `var(--sh-md)`) holding a 30px player icon tinted by hardware. Status pill top-left uses the light variant (`rgba(255,255,255,.92)` bg, `--ink-800` text): "● Online · up {uptime}" or "Offline".

Hardware tones: Amazon Fire TV Stick 4K `#ff9900` · RePlay Signage Stick `#2f6bff` · Raspberry Pi 4 (4GB) `#c51a4a` · fallback `#5b6470`.

**Head** — device name in **monospace** at 19px / 700 with an Online/Offline badge, subline `{hardware} · {site}`, tabs: Overview / Diagnostics / Activity.

**Tabs**

*Overview*
- Offline alert: "Unreachable since **2 hours ago**. **{screen}** is dark. Most often this is a pulled power cable or a dropped Wi-Fi network." + `Troubleshoot`.
- Stale-firmware alert (warn variant, online devices only): "Running **v{version}** — two versions behind. Update to **v2.8.1**." + `Update`.
- Three StatCards: **Uptime** (green online / red offline), **Firmware** (amber when stale, else blue), **Restarts (30d)** (violet).
- **Assigned screen** — a `.dw-card` with a real mini render of what that screen is playing, the screen name, its playlist, and a status Badge. Empty: "Not assigned to a screen."
- **Device** — rows: Hardware, RePlay app (mono version), Device ID (mono, uppercase `RP-…`), Site, Paired date, Uptime.

*Diagnostics*
- **Connectivity** rows: Network ("Vantage-Guest · Wi-Fi 5 GHz"), Signal (green "Strong (−48 dBm)" or red "No link"), IP address (mono), Last sync (mono). All collapse to "—" when offline.
- **Resources** — four meters `.dw-meter`: 96px label, flex-1 7px track (`--surface-3`, pill radius) with a colored fill, 40px right-aligned mono percentage. CPU (blue), Memory (teal), Storage (violet), Media cache (amber). CPU and Memory read 0% when offline.
- Three small secondary buttons: `Restart player`, `Pull logs`, `Clear cache`.

*Activity*
- "Hours online · last 14 days" + a 54px sparkline, teal when online / red when offline.
- Event log, same construction as the screen drawer: content sync or connection lost, playlist received, firmware update available or applied, player restarted, device paired.

**Footer** — `Reassign screen` (secondary → Screens), `Restart player` (primary).

---

## Interactions & Behavior

**Navigation**
- Listings card / row → listing detail route. Back link and the sidebar both return to the index.
- The route is dynamic (`listing-<id>`); the sidebar's active-section resolver must map any `listing-*` route back to the **Listings** nav item, and the topbar title becomes the property address with "Listing" as the subtitle.
- `Use in ad` (detail header, gallery card) → Ad Builder. Stop event propagation on the in-card button so it doesn't also trigger the card's navigation.
- Screens and Players open **drawers**, not routes — no URL change, and the underlying list stays mounted behind the scrim.

**Drawers**
- Open: 220ms slide from the right with a fade, `cubic-bezier(.2,.9,.3,1)`.
- Close: backdrop click, ✕ button, or Escape (bind the key listener while open, unbind on unmount).
- Only the body scrolls; hero, head, and footer are pinned.
- Tab switches are instant, no transition.

**Hover states**
- Card/row hover (`.ld-ad`, `.dw-card`): border → `--slate-300`, background → `--surface-2`, 150ms.
- Clickable names (`.scr-link`): color → `--blue-strong`.
- Feature toggle chips: 140ms all-property transition; hover raises the border to `--slate-300`.
- `.le-drop` dropzone: border → `--slate-300`.

**Form behavior**
- Fully controlled inputs; the price field's label swaps between "List price ($)" and "Monthly rent ($)" as the status select changes.
- The amenity chip pool is derived from the selected property type, so changing type changes the offered chips.
- Disabled submit until the three required fields are filled.

**Responsive**
- ≤1080px: listing-detail body grid → 1 column; spec strip wraps to 3-up rows.
- Drawers: `min(Npx, 100%)` — full-bleed on narrow viewports.

---

## State Management

**Listing detail** — reads one record by id from the route. No local state beyond what the parent passes (`id`, a navigate function, and an `openEditor(id)` callback).

**Listing editor** — `form` object (all fields), `selectedFeatures` array. Initialized from the existing record in edit mode, from defaults in create mode.

**App shell** — holds `editor: {id} | null` so the modal can be opened from either the Listings index (no id) or the detail page (with id), plus a force-render counter so an in-place edit repaints the detail page. In a real codebase replace this with your data layer's mutation + cache invalidation.

**Screens page** — `detail: screen | null` alongside the existing view/filter/selection state.

**Players page** — `detail: player | null` alongside the existing registration-modal state.

**Both drawers** — a local `tab` string.

**Data fetching (real implementation):** listing by id; ads filtered by listing; screen with its player, site, current playlist, and 14-day scan series; player with its assigned screen, connectivity, and resource telemetry. The prototype fakes the time series deterministically from an id-derived seed.

---

## Design Tokens

All tokens are CSS custom properties defined in `assets/replay.css`. **Use the tokens, never raw hex.**

**Accent**
| Token | Value |
|---|---|
| `--blue` | `#2f6bff` (primary accent) |
| `--blue-strong` | darker blue for text on light |
| `--blue-soft` | pale blue tint for icon tiles and active chips |
| `--teal` | `#0fb5a6` (secondary accent) |

**Status**
| Token | Value |
|---|---|
| `--green` / `--green-soft` | `#1f9d57` |
| `--red` / `--red-soft` | `#e5484d` |
| `--amber` | `#e8990f` |
| violet (charts) | `#7c5cff` |

**Neutrals** — `--ink-900 #0b0d12`, `--ink-800 #14171f`, `--ink-700 #1c2029`, `--ink-600 #2a2f3a`, `--ink-500 #3b414e`, then `--slate-500/400/300`, surfaces `--surface`, `--surface-2`, `--surface-3`, and lines `--line`, `--line-2`.

**Radius** — `--r-md` (cards, rows, tiles), `--r-xl` (modals), `--r-pill` (chips, badges, meter tracks). Bezels use a literal 6px; the device icon tile uses 18px.

**Shadows** — `--sh-xs`, `--sh-sm`, `--sh-md`, `--sh-lg`, `--sh-pop` (drawers and modals). *(Note: `--sh-1` does not exist — an earlier draft referenced it and rendered no shadow.)*

**Typography scale (as used here)**
| Role | Size / weight / tracking |
|---|---|
| Drawer title | 21px / 700 / -0.02em |
| Page `h2` | 20px / 700 / -0.02em |
| Big stat | 30px / 700 / -0.02em |
| Price cell | 24px / 700 |
| Spec value | 20px / 700 / -0.02em |
| Device name (mono) | 19px / 700 |
| Section `h3` | 15px (page) / 13.5px (drawer), 650 |
| Body copy | 14px / 1.65 |
| Row label + value | 13.5px |
| Meta / caption | 12–12.5px |
| Eyebrow | 11px / 650 / uppercase / 0.06em |
| Mono values | 12.5px |

Numerals in stats and tables use tabular figures.

**Spacing** — 4 / 6 / 8 / 10 / 12 / 14 / 18 / 20 / 22 / 24px. Card padding 18–22px, drawer body `20px 24px 24px`, drawer head `18px 24px 0`, footer `14px 24px`, gallery gap 10px, column gap 18–20px.

---

## Assets

**No image assets.** Every photograph is an intentional placeholder — a labeled empty block (`<div class="ph" data-label="hero photo">`) tinted by the listing's `tone` color. Do not substitute stock imagery or hand-draw illustrations in SVG; wire these to the real photo pipeline when you implement.

**Icons** are a single inline 24px stroke set (`currentColor`, consistent stroke width), rendered through one `Icon` component taking `name` / `size` / `sw`. Names used here: `sites, screens, players, playlists, ads, qr, grid, list, plus, check, x, chevronR, chevronD, dots, upload, download, refresh, wifi, wifiOff, zap, link, filter, search, bell`. Swap these for the target codebase's icon library — match the weight, not the exact paths.

**Fonts** — the existing app UI stack plus a monospace face for identifiers, versions, IPs, counts, and timestamps.

---

## Data

New per-listing fields introduced by this work: `year`, `mls`, `dom` (days on market), `agent`, `lscans` (30-day QR scans), `desc`, plus the existing `tone` used for placeholder tinting.

**Amenity pools by property type**
- *Townhouse* — Private garden, Finished basement, Original detail, Central air, Washer / dryer, Off-street parking
- *Condo* — Doorman, Fitness center, Common roof deck, Floor-to-ceiling glass, In-unit laundry, Storage unit
- *Co-op* — Pre-war detail, Hardwood floors, Live-in super, Elevator building, Bike storage, Pet friendly
- *Apartment* — In-unit laundry, Stainless appliances, Hardwood floors, Pet friendly, High ceilings, Dishwasher

**Display models by orientation** — Landscape `55" Commercial LCD` @ 1920×1080 · Portrait `49" Portrait LCD` @ 1080×1920.

Rentals are distinguished from sales by `price < 100000` — this drives the price label, the fifth spec cell, and the editor's price field label.

---

## What Is Intentionally Fake

There is no backend. Publish, Sync MLS, Restart, Update, Pull logs, Clear cache, billing, and API keys are all placeholders by design. The uptime figures, resource meters, signal strength, IP addresses, and time series are generated deterministically from an id-derived seed. Wire these to real telemetry — do not treat the hardcoded values as a spec for the numbers themselves, only for their presentation.

---

## Files

Prototype source included in this bundle, under `source/`:

| File | Contains |
|---|---|
| `RePlay Admin.html` | App entry — script load order and mount point |
| `admin.css` | All styles for this work: `.ld-*` (listing detail), `.le-*` (listing editor), `.dw-*` (drawers) |
| `replay.css` | Design tokens — the source of truth for every color, radius, and shadow above |
| `js/screens-listing-detail.jsx` | `ListingDetail` page + `ListingEditor` modal |
| `js/screens-detail-drawers.jsx` | Shared `Drawer` shell, `ScreenDetail`, `PlayerDetail` |
| `js/screens-content.jsx` | Listings index — the entry points into the detail page and editor |
| `js/screens-screens.jsx` | Screens index + `ScreenContent`, the live-preview renderer reused in both drawers |
| `js/screens-players.jsx` | Players index — drawer entry points |
| `js/shell.jsx` | Shared UI: `StatCard`, `Sparkline`, `Badge`, `Avatar`, `Note`, `Segmented`, sidebar/topbar |
| `js/data.jsx` | Mock listings, screens, players, sites, ads |
| `js/icons.jsx` | The full icon set |
| `js/app.jsx` | Router, route→screen map, drawer/modal hosting |
| `SPEC.md` | Broader product context for RePlay |
| `PROTOTYPE_CONVENTIONS.md` | Prototype-only conventions (no build step, `window` globals, etc.) — context for reading the source, **not** rules to carry into production |
