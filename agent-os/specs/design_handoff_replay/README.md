# RePlay — Complete Design Handoff

**RePlay** is a real-estate digital-signage SaaS platform. It replaces printed property sheets in brokerage, leasing, and sales-gallery storefront windows with dynamic digital displays that pedestrians can scan.

This package contains the full design for the product: an admin platform (13 screens), the signage playback experience, and the mobile QR landing experience — plus the design system they all share.

---

## About the design files

Everything in `source/` is a **design reference created in HTML/JSX** — high-fidelity, interactive, in-browser prototypes that demonstrate the intended look, layout, and behavior. They are **not production code to copy directly.**

The prototypes deliberately use no build step, in-browser Babel transpilation, `window` globals instead of modules, hash-based routing, and hardcoded mock data. Those are prototyping shortcuts, not architectural recommendations.

**Your task is to recreate these designs in the target codebase's existing environment** — React, Vue, SwiftUI, native, whatever the app is built in — using its established component library, routing, data layer, and styling conventions. If no environment exists yet, choose the framework most appropriate for the project and implement there.

Two things *do* transfer directly and should be treated as authoritative:
1. **The design token system** (`source/assets/replay.css`) — port it wholesale into whatever styling system you use.
2. **The information architecture** — the nav structure, route map, and object model.

## Fidelity

**High-fidelity throughout.** Colors, typography, spacing, radii, shadows, interaction states, copy, and empty/error states are all final and deliberate. Recreate them accurately. Every measurement in these documents is exact.

---

## Read in this order

| Document | What's in it |
|---|---|
| **`01-design-system.md`** | Tokens, type scale, base components, shared React components, imagery convention. Read first — everything else references it. |
| **`02-admin-app.md`** | The admin platform: shell, navigation, and all 13 screens with layouts, components, and behaviors. |
| **`03-detail-views.md`** | Deep spec for the listing detail page, listing editor, and the screen/player slide-over drawers — the most recently designed and most precisely documented surfaces. |
| **`04-playback-and-mobile.md`** | The signage playback screens and mobile QR landing screens. |
| **`05-implementation-notes.md`** | State model, data model, interaction patterns, responsive rules, accessibility, known gotchas, and the backlog of what's deliberately unbuilt. |

---

## The product in one diagram

```
Account ──owns──> Site (brokerage / leasing office / sales gallery / event popup)
                    │
                    └─has─> Screen (physical display) ──driven by──> Player (Fire Stick / Signage Stick / Raspberry Pi)

Listing (property, synced from MLS)
   └─becomes─> Ad (marketing creative; types: listing / branding / recruiting / open-house / promo)
                  ├─grouped by─> Campaign (+ scheduling)
                  └─sequenced in─> Playlist (ordered loop) ──assigned to──> Screen(s)

Analytics measures the whole chain via QR scans, screen activity, and engagement.
```

**The flow the UI must make obvious:** Listing → Ad → Playlist → Screen, measured by Analytics.

## Who uses it

All primary users are **non-technical**: Brokerage Owner, Office Manager, Marketing Manager, Leasing Manager, Sales Gallery Manager. The account in every prototype is hardcoded to **Vantage Realty**, signed in as **Maya Chen, Office Manager**.

This drives a consistent design bias throughout: **visual management over dense tables**. Card grids and live thumbnails are the default view; tables are one click away for power users. Every list view leads with the thing that breaks (offline devices, dark screens, stale firmware) rather than burying it in a status column.

## Design north star

Modern, premium, clean, trustworthy, media-centric. Reference points: Linear, Vercel, Stripe Dashboard, Notion, Figma, Framer, Arc.

Explicitly avoided: clutter, enterprise ugliness, and old CMS / MLS-software conventions.

---

## Three deliverables

**1. Admin platform** (`source/admin/`) — where managers create content and run the screen network. Sidebar + topbar shell, 13 routes, two full-bleed builders, a command palette, and a publish workflow.

**2. Screen playback** (`source/playback/`) — the full-screen storefront experience pedestrians see. Presented as a pan/zoom board of signage frames in landscape and portrait.

**3. Mobile QR landing** (`source/mobile/`) — where a pedestrian lands after scanning a QR code on a screen. Presented as a board of phone-sized screens.

A home hub (`source/index.html`) links all three and showcases the design system.

---

## Running the prototypes

All static — no server or build required beyond serving the folder. Open `source/index.html` for the hub, or any of:
- `source/admin/RePlay Admin.html`
- `source/playback/Playback Board.html`
- `source/mobile/Mobile QR.html`

The admin app keeps its route in the URL hash, so you can deep-link any screen (e.g. `…/RePlay Admin.html#analytics`).

---

## What is intentionally fake

There is no backend. **Publish**, **Sync MLS**, **Restart**, **Update**, **Pull logs**, **Clear cache**, billing, and API keys are all placeholders by design — do not treat them as bugs. Uptime figures, resource meters, signal strength, IP addresses, and all time-series data are generated deterministically from seeds.

Wire these to real systems. The hardcoded values are a spec for **presentation**, not for the numbers themselves.

Likewise, **every photograph is a labeled placeholder**, never a real or drawn image. See the imagery convention in `01-design-system.md`.
