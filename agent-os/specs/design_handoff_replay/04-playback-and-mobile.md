# 04 — Screen Playback & Mobile QR

The two pedestrian-facing surfaces. Neither has navigation — both are presented as **pan/zoom boards of frames** so the whole content system can be reviewed at once.

---

## Screen Playback (`source/playback/`)

What a pedestrian sees in the storefront window. Each screen is a self-contained `.pb` frame.

### The scaling rule

Every frame sets `container-type: size` and sizes **all** type in `cqw` / `cqh` units. This is non-negotiable: the same component must render correctly at 1920×1080 on a real display, at 640×360 on the review board, and at thumbnail size inside the admin's screen grid.

Board sizes: **landscape 640×360** (16:9) and **portrait 300×533** (9:16).

### Screen catalogue

Organized by the role each screen plays in the loop — this sequence *is* the content strategy, and a well-built playlist walks through it.

| Role | Variants | Job |
|---|---|---|
| **Hook** | `HookKinetic` (kinetic type), `HookPhoto` (photo + listing count), `HookMinimal` (light) | Stop the pedestrian. Big, fast, readable at 15 feet. |
| **Hero listing** | `HeroCinematic` (dark), `HeroEditorial` (light), `HeroLuxury` (split) | The conversion moment — one property, its price, its QR. |
| **Browse grid** | `BrowseGrid` (3-up) | Breadth: several listings at once. |
| **Open house** | `OpenHouse` (gradient, oversized date) | Event promotion. |
| **Branding** | `BrandAwards` (stats), `BrandTestimonial` | Trust building between listings. |
| **Recruiting** | `Recruiting` | Agent hiring. |
| **CTA** | `CtaGiant` (giant QR), `CtaSplit` | The closer — drive the scan. |
| **Portrait** | `HeroPortrait`, `CtaPortrait` | 9:16 variants for vertical windows. |

Helpers: `QR` (a CSS-grid fake QR — replace with real generated codes) and `Mark` (the logo mark).

### Motion

Entrance animations live in `playback.css` as utility classes: `pb-rise` (translate + fade up), `pb-fade`, `pb-ken` (Ken Burns drift on background media), staggered via `.d1`–`.d4`.

They are `both`-filled and play on load. **Two consequences:**
1. Screenshot tools capture them mid-fade — they look broken in static captures but are correct live. Verify motion in a real browser.
2. If you add more, keep the **visible end state as the base style** and let the animation move *toward* it, so a frame with animations disabled still renders correctly.

### Legibility rules to preserve

Storefront signage is read from the sidewalk, through glass, often in daylight. The designs reflect this:
- Headlines run 3.4–4.4cqw — enormous relative to the frame.
- Price is always among the largest elements on a hero screen.
- Text sits over scrims or solid panels, never directly on unmodified photography.
- Body copy is capped by `ch` limits (16ch headlines, 30–34ch subheads) so lines stay short.
- The QR is never smaller than ~20% of the frame's short edge, and always carries a CTA line telling the viewer what scanning does.

---

## Mobile QR Landing (`source/mobile/`)

Where a pedestrian lands after scanning. A board of iPhone-sized frames at **366×792**, each a `.mob` frame with a status bar and a sticky bottom CTA bar.

| Screen | Content |
|---|---|
| `Landing` | Listing detail — dark photo hero, price, specs, amenity chips, and a sticky bottom bar with Call and Schedule actions. |
| `LandingScroll` | The scrolled state — map, agent card, and a "more in this area" rail. Documents what's below the fold. |
| `Gallery` | Full photo grid. |
| `Schedule` | Date calendar plus time-slot selection — the booking flow. |
| `LandingEditorial` | An alternate treatment: calm, light, centered, luxury-leaning. A **design alternative**, not a separate route — pick one direction when implementing. |

Helpers: `StatusBar`, `QRm`, and an inline `MI` icon path set.

### Design intent

This is a **conversion page reached in a few seconds on a phone, standing on a sidewalk**. It is not a listing site. The priorities, in order:

1. Confirm they're looking at the right property (hero photo + address above the fold).
2. Price and key specs without scrolling.
3. A permanently visible way to act — the sticky CTA bar never scrolls away.
4. Everything else — gallery, map, agent, neighborhood — below the fold.

The same container-query approach applies: the phone frame is a container and content scales to it.

---

## Cross-surface consistency

The pedestrian journey is **screen → scan → phone**, and the two surfaces must feel like one product:

- The property photo, price, and address should be recognizably the same treatment on both.
- Brand color and logo come from the same Settings → Branding record that themes the ads.
- The QR code on a screen is tracked per-ad, which is what makes the admin's scan analytics work. Every QR must carry its source ad and screen.
