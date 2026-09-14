# Plan: Go Page Enhancements

**Created:** 2026-09-14
**Status:** Draft
**Branch:** `go-page-enhancements`

## Problem

The consumer-facing Go pages (`/go/listings/:id`, `/go/agents/:id`)
are functional but minimal. These are the landing pages that QR scans,
SMS links, and NFC taps all point to — they're the conversion surface
for every lead capture channel. They need to feel polished and give
visitors a reason to fill out the form.

## Current State

**Listing Go page** has:
- Single hero photo (first photo only)
- Price, status badge, address, specs
- Grid of additional photos (no gallery, no swipe)
- Lead form
- Agent contact cards

**Missing:**
- Swipeable photo gallery (mobile-friendly)
- Floor plan display
- Description text
- "Get directions" link
- Agent branding more prominent (above the fold)
- Social share / copy link
- Listing type badge (For Sale / For Rent)

**Agent Go page** has:
- Photo, name, contact info
- Active listings grid
- Lead form

**Missing:**
- Bio/description field (no column on Agent yet)
- Social links

## What to Build

### Listing Go Page

1. **Swipeable photo gallery** — Replace the static grid with a
   horizontal swipeable gallery (CSS scroll-snap, no JS library).
   Counter badge showing "3 / 12". Full-screen tap-to-zoom optional.

2. **Floor plan section** — Show floor plans below photos if the
   listing has them attached. Simple image display.

3. **Description** — Render `@listing.description` below specs
   if present. Clamp to 4 lines with "Read more" expand.

4. **Listing type badge** — "For Sale" / "For Rent" badge next to
   the status badge.

5. **Agent card above the fold** — Move the primary agent card above
   the lead form. Photo, name, phone (tap-to-call), email. Make it
   feel like "your agent" not just a contact section.

6. **Get directions** — Link to Google Maps with the listing address.
   Simple `href="https://maps.google.com/?q=ADDRESS"`.

7. **Share button** — Web Share API on mobile (native share sheet),
   fallback to copy-link on desktop.

8. **Remove scan_id from form** — Already removed from controller
   in the QrScan migration. Clean up the hidden field in the form
   partial.

### Agent Go Page

9. **Bio section** — Requires adding a `bio` text column to `agents`.
   Display below the contact info if present.

## Execution

### Step 1 — Clean up form partial
- Remove `scan_id` hidden field from `go/leads/_form.html.erb`

### Step 2 — Photo gallery (TDD)
- **RED:** Request spec asserting multiple photos render in a gallery container
- **GREEN:** Replace static grid with scroll-snap gallery + counter

### Step 3 — Floor plans, description, listing type badge
- Add floor plan section, description with clamp, listing type badge
- Template changes only, no new specs needed

### Step 4 — Agent card above the fold
- Move primary agent card above the lead form
- More prominent styling with tap-to-call

### Step 5 — Get directions + share
- Google Maps link from address
- Web Share API button with copy-link fallback

### Step 6 — Agent bio (TDD)
- **RED:** Model spec for bio presence
- **GREEN:** Add `bio` text column to agents, render on Go page

### Step 7 — Ship
- `make lint`, `make test`
- Push, create PR

## Out of Scope

- Full-screen photo zoom (can add later)
- Neighborhood data / Walk Score integration
- SEO / Open Graph meta tags (separate concern)
