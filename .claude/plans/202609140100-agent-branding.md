# Plan: Agent Branding on Listing Ads

**Created:** 2026-09-14
**Status:** Draft
**Branch:** `agent-branding`

## Problem

Listing ad layouts (hero, split, minimal, stat_grid) show zero agent
information — no photo, name, or phone. In NYC real estate, the agent
IS the brand. Storefront window displays and open house screens need
to prominently feature the listing agent.

The data path already exists: `Listing → ListingAgent → Agent` with
name, email, phone, and photo. The agent ad type (`AgentAd`) already
renders agent info with avatar, contact details, and accent styling.
But listing ads don't use any of it.

## Design

### Where the agent comes from

Each listing ad's agent is resolved via:

```ruby
ad.adable.listing.primary_agent
```

`primary_agent` returns the listing agent with `primary_at` set, or
falls back to the first agent. This is the same pattern the experience
kiosk uses.

### What renders

A compact agent strip at the bottom of each listing ad layout,
positioned above the QR badge. Contains:

- Agent photo (circular, falls back to initials)
- Agent name
- Agent phone (if present)

All sized with `cqw` variables so it scales with the ad canvas.

### Shared partial

Since the agent strip is identical across all four listing ad layouts,
it lives in a shared partial:

```
app/views/app/ads/layouts/_agent_strip.html.erb
```

Each layout includes it conditionally — only renders when the listing
has a primary agent. The partial receives `ad` as a local and resolves
the agent internally.

### Layout integration

| Layout | Placement |
|--------|-----------|
| **hero** | Bottom-left, above QR badge, over the gradient overlay |
| **split** | Bottom of the right content pane |
| **minimal** | Below the centered content block |
| **stat_grid** | Below the content block |

### Player manifest

The manifest Jbuilder for listing ads needs to include the primary
agent so the player-rendered version also shows agent branding.
Add agent data to `_listing_ad.json.jbuilder`:

```ruby
if listing_ad.listing.primary_agent
  json.partial! "api/players/manifests/agent", agent: listing_ad.listing.primary_agent
end
```

### No new models or migrations

Everything uses existing data: `ListingAgent`, `Agent`, `primary_agent`.
No new columns, no new models.

## Execution

### Step 1 — Agent strip shared partial
- Create `app/views/app/ads/layouts/_agent_strip.html.erb`
- Compact horizontal layout: photo (initials fallback) + name + phone
- All sizing via `var(--s-*)` cqw variables
- Conditionally renders only when `ad.listing&.primary_agent` exists

### Step 2 — Integrate into listing ad layouts (TDD)
- **RED:** Write request spec asserting agent name appears on ad preview when listing has a primary agent
- **GREEN:** Add `<%= render "app/ads/layouts/agent_strip", ad: ad %>` to hero, split, minimal, stat_grid layouts

### Step 3 — Player manifest
- Add primary agent to listing ad Jbuilder partial
- Existing manifest specs should cover structure

### Step 4 — Lookbook previews
- Update `ListingAdPreview` to assign a primary agent to the listing
- Verify agent strip renders in Lookbook

### Step 5 — Seeds
- Ensure demo listing ads have listings with assigned agents
- Should already be the case from existing seeds

### Step 6 — Ship
- `make lint`, `make test`
- Push, create PR

## Out of Scope

- Agent selection UI on the listing ad form (uses primary_agent automatically)
- Agent branding on collection ads or brand ads (they have their own patterns)
- Configurable show/hide toggle per ad (always shows if agent exists)
