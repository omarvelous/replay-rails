# RePlay — Project Spec & Handoff

> **What this is:** A complete product design for **RePlay**, a real-estate digital-signage SaaS platform. It replaces printed property sheets in brokerage / leasing / sales-gallery storefront windows with dynamic digital displays. Built as high-fidelity, interactive HTML/React prototypes (not production code).
>
> **Status:** Design-prototype stage. Three deliverables built and working: (1) interactive Admin app, (2) Screen Playback board, (3) Mobile QR landing board — all linked from a home hub.
>
> **Last updated:** June 1, 2026

---

## 1. Product concept

RePlay = "Canva meets digital signage, for real estate." Two experiences over one domain model:

1. **SaaS Admin platform** — where non-technical managers create content and manage the screen network.
2. **Screen Playback** — the full-screen storefront-window experience pedestrians see.
3. **(+) Mobile QR landing** — where a pedestrian lands after scanning a QR on a screen.

**Primary users** (all mostly non-technical): Brokerage Owner, Office Manager, Marketing Manager, Leasing Manager, Sales Gallery Manager. Design bias: **visual management over dense tables**, Apple-level simplicity, enterprise-ready IA.

**Design north star:** modern, premium, clean, trustworthy, media-centric. Inspiration: Linear, Vercel, Stripe Dashboard, Notion, Figma, Framer, Arc. Avoid: clutter, enterprise ugliness, old CMS / MLS-software vibes.

### Domain model
```
Account ──owns──> Site (physical location: brokerage / leasing / gallery / event)
Site ──has──> Screen (physical display) ──driven by──> Player (Fire Stick / Signage Stick / Raspberry Pi)
Listing (property data, from MLS)
Ad (marketing content; may reference a Listing; types: listing/branding/recruiting/open-house/promo)
Campaign ──groups──> Ads (+ scheduling)
Playlist ──ordered sequence of──> Ads/slides ──assigned to──> Screen(s)
Analytics: QR scans, screen activity, engagement
```
Conceptual flow the UI must make obvious: **Listing → Ad → Playlist → Screen**, measured by **Analytics**.

---

## 2. Tech & architecture

- **Pure front-end.** No build step, no bundler. React 18.3.1 + ReactDOM + Babel Standalone loaded from unpkg with pinned versions + integrity hashes (see any HTML file for the exact tags — reuse them verbatim).
- **JSX is transpiled in-browser** via `<script type="text/babel" src="…">`. Each babel script gets its **own scope**; components are shared by assigning to `window` at the end of each file (`Object.assign(window, {...})` or `window.X = X`).
- **No `type="module"`.** No imports/exports. Globals only.
- **CRITICAL naming rule:** never use a global `const styles = {…}`. Name style objects uniquely (or use inline styles) — collisions across babel scripts break everything. (This project mostly uses inline styles + CSS classes.)
- **Styling:** plain CSS with CSS custom properties (design tokens). Heavy use of **container queries** (`cqh`/`cqw` units) so playback/ad screens scale type to any frame size.
- **State/routing:** admin uses `useState` + `location.hash` for routing (no router lib). Playback & mobile use the `design-canvas.jsx` starter component (pan/zoom board of artboards).
- **Canonical HTML** required (explicit closing tags, double-quoted attrs, no self-closed non-void elements) so the visual editor can direct-edit.

---

## 3. File map

```
index.html                      Home hub: brief, design-system showcase, IA map, links to all 3 deliverables
assets/replay.css               SHARED design tokens + base components (buttons, badges, inputs, cards, tables, .ph placeholders, logo)

admin/
  RePlay Admin.html             Entry point; loads React + all js/*.jsx in order
  admin.css                     Admin shell + screen styles (sidebar, topbar, builders, command palette, etc.)
  tweaks-panel.jsx              Starter component: Tweaks panel (accent color / density / corners)
  js/
    icons.jsx                   ICONS object + <Icon name size sw/> component (24px stroke icons, currentColor)
    data.jsx                    ALL mock data: SITES, SCREENS, PLAYERS, LISTINGS, CAMPAIGNS, ACTIVITY, TOP_ADS, ADS, PLAYLISTS, fmtPrice()
    shell.jsx                   Sidebar, Topbar (+Create menu), CommandPalette (⌘K), Segmented, Badge, StatCard, Sparkline, Avatar, Note, Donut, NAV
    screens-dashboard.jsx       Dashboard (setup checklist, quick actions, KPIs, scans chart, top ads, network health, activity)
    screens-sites.jsx           Sites (card/map toggle, NewSiteModal 2-step, SiteDetail slide-over)
    screens-screens.jsx         Screens (grid/table, filters, bulk bar, per-card "Change content" swap popover, live ScreenContent thumbnails)
    screens-players.jsx         Players (table, offline alert banner, RegisterModal pairing flow with 6-digit code)
    screens-content.jsx         Listings (gallery/table) + Campaigns (Gantt timeline + cards)
    screens-lists.jsx           AdsList (grid/table index) + PlaylistsList (rows w/ mini loop timeline)  ← index views
    screens-ads.jsx             Ads = the Ad Builder (Canva-like; template gallery, layout/theme, live AdPreview, Duplicate, back btn)
    screens-playlists.jsx       Playlists = the Playlist Builder (drag-reorder, duration nudge, loop timeline, preview, back btn)
    screens-analytics.jsx       Analytics (tabs: overview/sites/screens/ads/campaigns/qr; AreaChart, Heatmap, ranked bars)
    screens-settings.jsx        Settings (branding/team/billing/api) + PublishModal (review→published, version history, rollback)
    app.jsx                     App router: hash routing, tweaks application, ⌘K wiring, Topbar/CommandPalette/PublishModal mount

playback/
  Playback Board.html           design-canvas board of all signage screens (landscape 640×360 + portrait 300×533)
  design-canvas.jsx             Starter component (DesignCanvas, DCSection, DCArtboard) — pan/zoom, reorder, focus mode
  playback.css                  .pb signage frame styles + kinetic animation helpers (pb-rise/fade/ken, etc.)
  js/screens.jsx                All playback screens + QR/Mark helpers (see §6)

mobile/
  Mobile QR.html                design-canvas board of phone screens (366×792)
  mobile.css                    .mob phone-screen styles (status bar, sticky CTA, gallery, calendar)
  js/screens.jsx                Landing, LandingScroll, Gallery, Schedule, LandingEditorial, StatusBar, QRm

.design-canvas.state.json       Canvas pan/zoom/order persistence (auto-managed by starter component)
```

**Load order matters** in `RePlay Admin.html`: React → ReactDOM → Babel → tweaks-panel → icons → data → shell → screens-* → app. `app.jsx` must be last (it calls `ReactDOM.createRoot`).

---

## 4. Design system (in `assets/replay.css`)

### Color tokens
- **Foundation (cool-tinted neutrals):** `--ink-900 #0b0d12` … `--ink-500`, `--slate-500 #5b6470` (secondary text), `--slate-400 #8a929e` (tertiary), `--line #e6e8ec` (hairline), `--surface #fff`, `--surface-2 #f7f8fa` (app bg), `--surface-3`.
- **Dual accent:** `--blue #2f6bff` (+ `--blue-strong #1f54e0`, `--blue-soft #eaf0ff`) and `--teal #0fb5a6` (+ strong/soft). Blue is primary; teal is secondary/gradient partner.
- **Semantic:** `--green #1f9d57`, `--amber #e8990f`, `--red #e5484d` (each w/ `-soft` variant).
- Extra hues used in data viz: `#7c5cff` (violet), `#e8990f` (amber).

### Type
- `--sans`: system/Helvetica stack (`-apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, Arial`). `--mono`: SF Mono / JetBrains Mono stack for numerals & codes.
- Scale classes: `.t-display 40`, `.t-h1 28`, `.t-h2 21`, `.t-h3 16`, `.t-body 14`, `.t-sm 13`, `.t-xs 12`, `.t-label` (11 uppercase). `.mono`, `.tabular` for numbers. `.muted`/`.faint` for text color.

### Radii / shadow / layout tokens
- `--r-xs 6` … `--r-pill 999`. `--sh-xs` … `--sh-pop`. `--sidebar-w 248px`, `--topbar-h 60px`.

### Base components (classes)
`.btn` (+ `-primary/-secondary/-ghost/-danger/-sm/-lg/-icon`), `.field/.input/.select/.textarea`, `.search` (icon input), `.card/.card-pad`, `.badge` (+ color variants, `.dot`, `.pulse`), `.tbl` (thead/tbody styled), **`.ph`** (striped media placeholder; uses `data-label` attr for the mono caption — used everywhere for "drop real photo here").

### React-level shared components (in `shell.jsx`)
`<Icon>`, `<Sidebar>`, `<Topbar>`, `<CommandPalette>`, `<Segmented>`, `<Badge status>`, `<StatCard>`, `<Sparkline>`, `<Avatar>`, `<Note>` (rationale callout), `<Donut>`, `<PageGrid>`. `<MiniStat>` lives in screens-sites.jsx.

### Imagery convention
**Never hand-draw photos.** Use `<div class="ph" data-label="property photo">` placeholders (or inline gradient tints for signage). User will drop in royalty-free / real photos later.

---

## 5. Admin app — screens & key behaviors

Routing via `location.hash`. Nav groups (in `NAV`, shell.jsx): **Overview** (Dashboard, Analytics) · **Network** (Sites, Screens, Players) · **Content** (Listings, Ads, Campaigns, Playlists) · **Settings** (bottom).

Account context is hardcoded as **"Vantage Realty"** / user **"Maya Chen, Office Manager"**.

| Route | Component | Notes |
|---|---|---|
| `dashboard` | Dashboard | Dismissible **setup checklist** (activation), **quick actions** row, 5 KPIs, 12-mo scans bar chart, top-ads table, network-health donut, activity feed. |
| `sites` | Sites | Card grid ⇄ **map view** toggle; `NewSiteModal` (2-step create); `SiteDetail` right slide-over. |
| `screens` | Screens | Grid (live preview thumbnails via `ScreenContent`) ⇄ table; filters; **bulk action bar**; per-card **"Change content"** popover (swap playlist in place). |
| `players` | Players | Device table; **offline alert banner**; `RegisterModal` = guided pairing w/ 6-digit code + success state. |
| `listings` | Listings | Image gallery ⇄ table; "Use in ad" CTA per card. |
| `ads` | **AdsList** | Index: grid/table of all `ADS` w/ status, scans, scan-through, Duplicate. Click → `ad-builder`. |
| `ad-builder` | Ads | **Canva-like builder** (full-bleed): template gallery, layout (hero/split/minimal/stat-grid), theme (dark/light/brand), live `AdPreview` (container-query scaled), linked-listing select, auto QR. Back btn → `ads`. |
| `campaigns` | Campaigns | **Gantt-style schedule timeline** + campaign cards w/ performance. |
| `playlists` | **PlaylistsList** | Index: rows w/ site, screens, slides/duration, **mini loop timeline**, publish status. Click → `playlist-builder`. |
| `playlist-builder` | Playlists | **Spotify-style editor** (full-bleed): drag-reorder, per-slide duration nudge, proportional loop timeline, live preview panel. Back btn → `playlists`. |
| `analytics` | Analytics | Tabs: overview/sites/screens/ads/campaigns/qr. `AreaChart`, **foot-traffic Heatmap** (hour×day), ranked bars. |
| `settings` | Settings | Sub-tabs: branding / team & roles / billing (placeholder) / api (placeholder). Includes `PublishModal`. |

**Full-bleed routes** (`ad-builder`, `playlist-builder`) hide the Topbar and render edge-to-edge. Sidebar keeps the parent (`ads`/`playlists`) highlighted via a `section` alias in Sidebar.

### Cross-cutting admin features (added during critique pass)
- **Global `+ Create` menu** in Topbar → ad / listing / playlist / campaign / device.
- **Command palette (`⌘K`** or click search) → jump to any screen or quick-create. 13 targets.
- **Contextual Publish** button with pending-count pill (`Publish 2`).
- **Tweaks panel** (toolbar toggle): accent color (blue/teal/violet/amber), density (comfortable/compact), corners (rounded/sharp). Applied to `:root` vars in `app.jsx`. Defaults live in `TWEAK_DEFAULTS` between `/*EDITMODE-BEGIN*/…/*EDITMODE-END*/` markers.

---

## 6. Screen Playback board (`playback/`)

design-canvas board. Each screen is a self-contained `.pb` frame; type scales via container-query units so the same component works at any size. Sections + variants:

- **Hook** (stop the pedestrian): `HookKinetic` (kinetic type), `HookPhoto` (photo + count), `HookMinimal` (light).
- **Hero Listing** (conversion): `HeroCinematic` (dark), `HeroEditorial` (light), `HeroLuxury` (split).
- **Browse Grid**: `BrowseGrid` (3-up).
- **Open House**: `OpenHouse` (gradient, big date).
- **Branding**: `BrandAwards` (stats), `BrandTestimonial`.
- **Recruiting**: `Recruiting`.
- **CTA**: `CtaGiant` (giant QR), `CtaSplit`.
- **Portrait variants** (9:16): `HeroPortrait`, `CtaPortrait`.

Helpers: `QR` (CSS-grid fake QR), `Mark` (logo mark). Motion classes in `playback.css`: `pb-rise`, `pb-fade`, `pb-ken` (Ken Burns), staggered via `.d1`–`.d4`. **Note:** entrance animations are `both`-filled and play on load — html-to-image screenshots may capture them mid-fade (they're fine live). Keep visible end-state as base style if adding more.

---

## 7. Mobile QR landing (`mobile/`)

design-canvas board of iPhone-sized (366×792) screens. `.mob` frame w/ status bar + sticky bottom CTA bar.
- `Landing` — listing detail (dark hero, specs, chips, sticky call/schedule CTA).
- `LandingScroll` — scrolled state (map, agent card, "more in area").
- `Gallery` — photo grid.
- `Schedule` — date calendar + time slots.
- `LandingEditorial` — alternate calm/light/centered luxury treatment.
Helpers: `StatusBar`, `QRm`, inline `MI` icon paths.

---

## 8. Conventions & gotchas for continuation

- **Reuse the exact pinned React/Babel script tags** from an existing HTML file (with integrity hashes). Don't bump versions.
- **Share components via `window`** at the end of each jsx file; new screen files must be added to `RePlay Admin.html` script list **before `app.jsx`** and wired into the `Screen`/`titles` maps + `NAV` in `app.jsx`/`shell.jsx`.
- **Mock data is centralized** in `admin/js/data.jsx`. Add new entities there.
- **Placeholders not fake photos** — use `.ph[data-label]`.
- **Container queries**: signage/ad/mobile frames set `container-type: size`; children use `cqh`/`cqw` for type. Don't switch them to px.
- **Screenshots lie for overlays/animations** — fixed overlays (command palette, popovers) and entrance animations don't render in html-to-image; verify via live DOM (`eval_js`) instead.
- **Card overflow**: tiles that show popovers (e.g. screen "Change content") must keep `overflow: visible` on the card and clip only the inner media; lift the open card with `z-index`.
- No real backend; everything is client-state. "Publish", "Sync MLS", billing, API keys are intentional placeholders.

---

## 9. Suggested next steps / backlog

- **Listings → Ad builder** deep link (carry selected listing into a new ad).
- **Ad → Playlist** wiring (add a saved ad to a playlist from the builder).
- **Campaign detail / scheduling** flow (currently list + timeline only).
- Real **drag-and-drop from a media library** in the Ad builder.
- **Leasing / Sales-gallery manager** role-scoped views (settings has roles; views don't yet enforce scope).
- Second **Browse Grid** layout; more open-house / branding variants.
- **Empty states** for a brand-new account (setup checklist exists; per-screen empty states don't).
- Wire Tweaks accent through **playback & mobile** too (currently admin-only).
- Production port: this is prototype HTML; a real build would move to a bundler + component lib, but the token system and IA transfer directly.

---

## 10. How to run / view

Open `index.html` (the hub) → links to Admin / Playback / Mobile. Or open any of:
- `admin/RePlay Admin.html`
- `playback/Playback Board.html`
- `mobile/Mobile QR.html`

All are static; just serve the folder. Admin remembers route in the URL hash; canvases remember pan/zoom/order in `.design-canvas.state.json` + localStorage.
