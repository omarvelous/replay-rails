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
| 2 | Touch/interactive player mode | No | Large | Must-have |
| 3 | On-screen lead capture (touch) | No | Medium | Must-have |
| 4 | StreetEasy listing import | No | Large | Should-have |
| 5 | Mobile UX polish | Partial | Small-Med | Should-have |
| 6 | Go page enhancements | Partial | Small | Should-have |
| 7 | Neighborhood content | No | Large | Nice-to-have |

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

### 2. Touch/interactive player mode

**Current state:** The `play` subdomain renders a passive slideshow via
a Stimulus controller. Auto-advancing slides, no user interaction. No
touch event handlers, no swipe, no navigation controls.

**What to build:**
- New player mode: `passive` (current) vs `interactive`
- Interactive mode adds:
  - Swipe/tap navigation between slides
  - Photo gallery browsing (swipe through listing photos)
  - Pinch-to-zoom on photos/floor plans
  - Navigation UI (dots, arrows, back button)
  - Idle timeout: return to auto-play after N seconds of no touch
- Mode flag on Screen or Playlist to toggle behavior
- New Stimulus controller or mode branch in existing one
- Responsive layout for both landscape (window) and portrait (stand)

**Complexity:** Large. New interaction paradigm, touch gesture handling,
different UX from passive signage. Core to the open house product.

### 3. On-screen lead capture form (touch mode)

**Current state:** QR scan → `/go/listings/:id` → lead form works
end-to-end. But there's no on-screen form for visitors standing at
the screen itself. The existing QR flow requires a phone.

**What to build:**
- Touch-to-submit lead form rendered on the player screen
- "Enter your email to get the floor plan" gated content pattern
- Minimal fields: name, email, phone (optional)
- Lead created with `lead_type: "open_house_rsvp"` and linked to listing
- Confirmation screen: "Thanks! Check your email."
- Optional: email triggers a follow-up with listing details/floor plan
- Privacy: clear screen after submission, idle timeout

**Complexity:** Medium. Lead model and create endpoint exist. Need a
form in the player context with touch-friendly input and on-screen
keyboard considerations.

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

### Sprint 1: Demo-ready (1-2 weeks)
1. Agent branding on listing ads (small)
2. Go page polish (small)

### Sprint 2: Interactive mode (2-3 weeks)
3. Touch/interactive player mode (large)
4. On-screen lead capture form (medium)

### Sprint 3: Convenience (1-2 weeks)
5. Mobile UX polish (small-medium)
6. StreetEasy import (large — consider deferring)

### Sprint 4: Depth (as needed)
7. Neighborhood content (large — defer until customer demand)
