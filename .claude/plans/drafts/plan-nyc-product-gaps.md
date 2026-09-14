# Plan: NYC Launch — Product Gaps

## Context

Based on the NYC go-to-market analysis (`.claude/analysis/nyc-go-to-market.md`),
the product needs to support two motions: storefront window displays and
portable open house signage. This plan identifies what exists today, what's
missing, and what needs to be built.

---

## Gap Summary

| # | Feature | Exists? | Size | Priority |
|---|---------|---------|------|----------|
| 1 | Agent branding on listing ads | Partial | Small | Must-have |
| 2 | Touch/interactive player mode | **Shipped** (Experiences) | — | — |
| 3 | Lead capture channels | Partial (QR only) | Medium | Must-have |
| 4 | StreetEasy listing import | No | Large | Deferred |
| 5 | Mobile UX polish | Partial | Small-Med | Should-have |
| 6 | Go page enhancements | Partial | Small | Should-have |
| 7 | Neighborhood content | No | Large | Deferred |

---

## Must-Have (Blocks Phase 1 Demos)

### 1. Agent branding on listing ads

**Current state:** Agent model has name, email, phone, photo. `AgentAd`
type exists with `profile` and `split` layouts. But listing ad layouts
(`hero`, `split`, `minimal`, `stat_grid`) show zero agent info — no
photo, name, or phone.

**What to build:**
- Add agent overlay/section to listing ad layout partials
- Show agent photo, name, phone on the ad itself
- Toggle or always-on — could be driven by listing_agents association
- Agent branding should also appear on the player-rendered version

**Complexity:** Small. Data and associations exist. Template changes only.

### 2. Touch/interactive player mode — SHIPPED

Delivered as the Experiences feature. `ListingExperience` with kiosk
player rendering, photo gallery navigation, floor plans, agent card,
QR handoff, idle/attract mode, and touch detection. See
`.claude/plans/202609050300-experiences.md`.

### 3. Lead capture channels

**Current state:** QR scan → Go page → lead form works end-to-end.
But QR is the only capture channel. Not everyone wants to scan a code.

**Design principle:** The kiosk should stay browse-only. All lead
capture should move the visitor to their own device — never block the
shared screen with a form and keyboard.

**Channels (in priority order):**

| Channel | How it works | Status | Needs |
|---------|-------------|--------|-------|
| **QR code** | Scan → Go page → lead form on phone | **Working** | Go page enhancements (gap #6) |
| **SMS keyword** | "Text LISTING to 55555" → auto-reply with Go page link | **Needs plan** | Twilio, inbound number, keyword routing |
| **NFC tap** | Tap phone on tag → opens Go page | **Needs plan** | NFC tags per screen ($0.50/tag), provisioning |
| **On-screen form** | Full form on kiosk touch screen | **Deferred** | Last resort — blocks the kiosk for other visitors |

**SMS — what to build:**
- Twilio account with an inbound number
- SMS keyword routing: text a listing-specific code, get back a link
- Lead captured from the phone number (opt-in for follow-up)
- Auto-reply: "View this listing: [Go page URL]. Reply STOP to opt out."
- Display on the kiosk: "Text OPEN to (212) 555-1234"

**NFC — what to build:**
- NFC tags provisioned per screen or per listing
- Tag stores the Go page URL (same as QR destination)
- Tap → phone opens Go page → lead form
- Inventory angle: tag ID can tie to screen location for admin/maintenance

**On-screen form — deferred:**
Documented as a last-resort option. Not planned for build. Only makes
sense for dedicated tablets at a staffed check-in desk, not shared
storefront displays. If built later, would be a single email field
("Email me this listing") rather than a full form.

---

## Should-Have (Blocks Phase 2 Domination)

### 4. StreetEasy listing import

**Current state:** Listings are created manually. No external data
import of any kind.

**What to build:**
- "Import from StreetEasy" option on new listing form
- Paste a StreetEasy URL → fetch and parse listing data
- Extract: address, price, beds, baths, sqft, photos, description
- Pre-fill the listing form, user confirms and saves
- Handle: URL validation, fetch errors, missing data gracefully

**Complexity:** Large. StreetEasy has no public API — requires
scraping or structured data extraction from HTML. Fragile, may
require ongoing maintenance. Legal considerations around
scraping terms of service.

**Alternative:** Start with manual entry (exists today) and add
"paste URL" as a convenience later. Don't block launch on this.

### 5. Mobile UX polish for content updates

**Current state:** App is responsive — viewport meta, mobile sidebar,
responsive grid classes. Agents/brokers can manage listings and ads
from a phone browser. But the UX hasn't been tested/optimized for
key mobile flows.

**What to build:**
- Audit and optimize: create listing, upload photos, update ad,
  manage playlist on mobile screens
- Ensure photo upload from camera roll works smoothly
- Test touch targets, form layouts, modals on small screens
- Optimize the most common "quick update" paths

**Complexity:** Small-Medium. Infrastructure exists, needs QA and
targeted fixes. No architectural changes.

### 6. Go page enhancements

**Current state:** Three consumer-facing routes exist:
- `go/listings/:id` — listing detail with lead form
- `go/agents/:id` — agent profile page
- `go/leads` — lead create endpoint

These are functional but minimal.

**What to build:**
- Better mobile styling for open house visitors
- Agent branding more prominent on listing go page
- Photo gallery (swipeable on mobile)
- Floor plan display (if available)
- Social share buttons
- "Get directions" link (Google Maps)

**Complexity:** Small. Pages exist, need enhancement.

---

## Nice-to-Have (Phase 3+)

### 7. Neighborhood content

**Current state:** Nothing exists. No models, fields, or views for
transit, restaurants, schools, or neighborhood info.

**What to build:**
- Neighborhood data sourcing (Walk Score API, Google Places, or
  manually curated per listing)
- "Live Here" section on listing ads and go pages
- Transit proximity, nearby restaurants, school ratings
- New ad layout or section for neighborhood storytelling

**Complexity:** Large. Data sourcing is the hard part. Consider
starting with a free-text "neighborhood highlights" field on
Listing before building an API integration.

---

## Already Working

These features exist and support the NYC launch as-is:

- **QR scan → lead form flow** — end-to-end functional
- **Agent data model** — name, email, phone, photo, linked to users
- **Listing management** — photos, specs, status, description
- **Ad builder** — delegated types with layout partials and themes
- **Playlist → screen pipeline** — content assignment and playback
- **Lead inbox** — status tracking, agent assignment, search
- **Consumer go pages** — listing detail and agent profile with lead form
- **Multi-tenant architecture** — account isolation, roles, invites

---

## Suggested Build Order

### Sprint 1: Demo-ready
1. Agent branding on listing ads (small — template changes)
2. Go page enhancements (small — photo gallery, agent branding, directions)

### Sprint 2: Capture channels
3. SMS keyword lead capture (medium — Twilio integration)
4. NFC tap-to-view (small-medium — tag provisioning, URL scheme)

### Sprint 3: Polish
5. Mobile UX audit (small-medium — QA key flows on phone)

### Deferred
- StreetEasy import — no public API, scraping is fragile
- Neighborhood content — wait for customer demand
- On-screen lead form — last resort, not planned
