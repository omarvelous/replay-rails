# 05 — Implementation Notes

Everything that isn't a screen: the data model, state, cross-cutting behaviors, and the traps.

---

## Data model

Mock data for the whole product is centralized in `source/admin/js/data.jsx`. Treat it as the schema.

### Site
`id, name, type, addr, screens, online, scans, color, x, y`
Types: Brokerage · Leasing · Sales Gallery · Event. `color` themes the site's cards, map pin, and analytics bar. `x`/`y` are percentage coordinates for the map view.

### Screen
`id, name, site, player, playlist, status, heartbeat, orient`
Status: `live` · `offline` · `idle` (no player paired). `orient`: Landscape · Portrait. `player` and `playlist` reference by name — in a real implementation these become foreign keys.

### Player
`id, name, site, screen, hw, version, status, uptime`
Hardware: Amazon Fire TV Stick 4K · RePlay Signage Stick · Raspberry Pi 4 (4GB). Status: `online` · `offline`. Current firmware is `2.8.1`; anything older renders amber.

### Listing
`id, addr, area, price, beds, baths, sqft, status, type, tone, year, mls, dom, agent, lscans, desc`
Status: Active · For Rent · Pending. Type: Apartment · Condo · Co-op · Townhouse. `tone` tints placeholder imagery. `dom` = days on market, `lscans` = 30-day QR scans.

**Rentals are distinguished by `price < 100000`** — this single check drives the price label ("List price" vs "Asking rent"), the fifth spec cell (price-per-sqft vs lease term), and the editor's price field label. Replace it with an explicit `listingKind` field in production; the heuristic is a prototype shortcut.

### Ad
`id, name, campaign, type, status, scans, ctr, tone, layout, updated`
Type: Listing · Branding · Recruiting · Open House · Promo. Status: `live` · `scheduled` · `draft`.

### Campaign
`id, name, scans, color`, plus scheduling dates for the Gantt view.

### Playlist
`id, name, site, screens, slides, dur, segs, status, version, updated`
`segs` is an array of `[color, widthPercent]` pairs driving the mini loop timeline. Status: `published` · `draft`.

### Playlist item (builder-local)
`id, name, type, dur, tone` — types: Hook · Hero listing · Open house · Browse grid · Branding · Recruiting · CTA. Durations clamp to 3–60s.

### Helpers
`fmtPrice(n)` formats sale prices as `$1.25M` / `$985K` and rents as `$4,200/mo`.

---

## State

The prototype uses local component state throughout — no store, no server cache. Map each of these to your data layer.

| Scope | State |
|---|---|
| App | `route` (hash-synced), `publishing`, `palette` (⌘K), `editor` ({id} or null), a force-render counter |
| Screens | `view`, `filter`, `sel[]` (bulk selection), `swap` (open popover id), `detail` (drawer) |
| Players | `reg` (register modal), `detail` (drawer) |
| Listings | `view`, `area` filter |
| Listing editor | full form object, `selectedFeatures[]` |
| Ads index / Playlists index | `view`, `filter` |
| Ad builder | one `ad` object — headline, sub, cta, price, specs, layout, theme, linked listing |
| Playlist builder | `items[]`, `sel`, `drag`, `over`, `library` |
| Library modal | `tab`, `picked[]`, `q` |
| Analytics / Settings / Sites | active tab / view, plus modal and drawer flags |
| Drawers | local `tab` |

**Routing.** `location.hash` with a single `go(route)` function threaded down as a prop. Dynamic routes use a prefix convention (`listing-<id>`). Replace with the target codebase's router — but keep the URL-addressable routes, and keep drawers *out* of the URL (they're transient inspection, not navigation).

**The force-render counter** in the app shell exists only because the prototype mutates the mock data array in place. In a real implementation this becomes mutation + cache invalidation and disappears.

---

## Cross-cutting interaction patterns

Apply these consistently — they're what makes the app feel coherent.

**Index → detail.** Every list has one. Cards and rows are both clickable; interactive controls inside them call `stopPropagation` so a button never triggers the row's navigation.

**Detail as page vs. drawer.** Listings get a **full page** (deep content, its own URL, shareable). Sites, screens, and players get **right slide-overs** (inspection in context, no navigation, no URL change, list stays visible behind the scrim). Follow this split for anything new: if a user would send someone a link to it, it's a page.

**Index-first, builder-second.** Ads and Playlists both open to a scannable library, never straight into the editor. Managing existing content is a far more common task than creating new content.

**Hover states.** Card and row hover: border → `--slate-300`, background → `--surface-2`, ~150ms. Clickable names: color → `--blue-strong`. Chips: 140ms all-property transition.

**Empty states.** Every list that can be empty has a designed one — dashed border, a soft-tinted icon tile, a one-line explanation, and a primary action. Never an empty container.

**Destructive and pending states.** Draft/pending is always amber; live/published is always green; offline/error is always red. This mapping never varies.

**Modals** center with a scrim; **drawers** slide from the right in 220ms on `cubic-bezier(.2,.9,.3,1)`. Both close on backdrop click, an explicit ✕, and Escape.

**Loading.** The register-device flow is the only intentional async state (a spinner resolving to success after ~2.6s). Everything else is instant by design. You'll need real loading states throughout — follow the spinner treatment used there.

---

## Responsive

The admin is designed for desktop (it's a management console used at a desk) but degrades:
- ≤1080px: the listing-detail body grid collapses to one column; the spec strip wraps to 3-up rows.
- Drawers are sized `min(Npx, 100%)` — full-bleed on narrow viewports.
- Card grids set explicit column counts per screen; make these responsive when you implement.

Playback and mobile frames are container-query driven and scale to any size by construction.

---

## Accessibility — gaps to close

The prototype covers the visual design, not the full a11y implementation. When building, add:
- Keyboard operation for drag-to-reorder in the playlist builder (currently mouse-only HTML5 drag). Offer explicit move-up/move-down actions.
- Focus traps and restoration for modals and drawers. Escape is wired; focus management is not.
- Real `aria-pressed` / `role="tab"` semantics on the segmented controls and tab bars (currently styled buttons).
- Labels on icon-only buttons — several have `title` attributes but not all.
- Contrast check on `--slate-400` (`#8a929e`) captions at 11–12px. It passes on white for larger text but is borderline at the smallest sizes; consider `--slate-500` for anything under 12px.
- Live-region announcements for status changes (device came online, publish completed).
- `prefers-reduced-motion` handling for the playback entrance animations and the pulse dots.

---

## Known traps

**Height-capping drawers.** The single biggest bug found in review. A right slide-over inside a grid-based scrim needs its track constrained (`grid-template-rows: minmax(0,1fr)`), the drawer given `height: 100%; max-height: 100%; min-height: 0`, and the scrolling body given `min-height: 0`. Without the full chain, the flex column grows to its content, the body never scrolls, and the footer sits off-screen. Reproduce the equivalent constraint chain in your layout system.

**Height-capped media.** Once the drawer hero is capped by `max-height`, anything inside it must be **height-driven** (`height: 100%; width: auto` + `aspect-ratio`), not width-driven, or it overflows and gets clipped.

**Card overflow vs. popovers.** Tiles that open popovers (the Screens "Change content" swap) must keep `overflow: visible` on the card and clip only the inner media, and lift the open card with `z-index`. Clipping the card kills the popover.

**Screenshots lie.** Fixed overlays (command palette, popovers, modals) and `both`-filled entrance animations do not render correctly in DOM-to-image capture. Verify these live in a browser, not from static captures.

**Container queries are load-bearing.** Converting signage/ad/mobile type from `cqw` to `px` or `vw` breaks multi-scale rendering everywhere those components appear.

**Tabular numerals.** Any number that updates (stats, durations, counters, timers) needs tabular figures or it jitters.

---

## Backlog — deliberately unbuilt

Designed-adjacent work that was scoped out. Useful as a roadmap; none of it is required to ship what's here.

- **Ad → Playlist wiring** from inside the builder (add a saved ad to a playlist without leaving).
- **Campaign detail / scheduling flow** — currently list + Gantt only, no detail view.
- **Real drag-and-drop media library** in the ad builder (the library picker exists for playlists, not ads).
- **Role-scoped views** — Settings defines roles, but no view enforces scope yet.
- **A second Browse Grid layout**, plus more open-house and branding variants.
- **Per-screen empty states** for a brand-new account. The dashboard setup checklist exists; individual screens assume populated data.
- **Wiring the accent tweak through playback and mobile** (currently admin-only).
- **Screen detail as a shareable route** if users start needing to link to a specific display.

---

## Porting checklist

1. Port `replay.css` tokens into your styling system first. Everything else depends on them.
2. Build `Icon`, `Badge`, `StatCard`, `Sparkline`, `Note`-replacement, `Segmented`, `Avatar`, `MiniStat`, `Drawer` — the shared vocabulary.
3. Build `ScreenContent` early. It appears in the screens grid, the screens table, the screen drawer, and the player drawer, at four different scales.
4. Build the shell (sidebar, topbar, command palette, routing) with the active-section aliasing.
5. Build index screens before detail screens; build detail screens before builders.
6. The two builders are the largest single pieces — budget accordingly.
7. Strip every `<Note>` before shipping.
