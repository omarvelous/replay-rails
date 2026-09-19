# Plan v2: Go Experience Page

**Created:** 2026-09-18 (v1), **Updated:** 2026-09-19 (v2)
**Status:** Draft

## Problem

`Go::ExperiencesController#show` renders `play/players/experience` —
a kiosk template designed for paired screen devices with heartbeat,
ActionCable, idle/attract mode. A consumer scanning a QR code on
their phone gets a full-screen kiosk UI instead of a mobile-friendly
landing page.

## Solution

The Go experience page is functionally the same as the Go listing
page — same property data, same layout — just entered via an
Experience URL with the experience's agent override instead of the
listing's primary agent.

The Go listing view (`go/listings/show.html.erb`) is already a
well-built mobile landing page with: photo gallery, price/specs,
description, floor plans, agent card, lead form, directions, share.

Rather than duplicate 150 lines, extract the shared sections into
Go partials and render them from both controllers.

---

## Step 1 — Extract shared Go partials

Move reusable sections from `go/listings/show.html.erb` into
`app/views/go/shared/`:

| Partial | What it renders |
|---------|----------------|
| `_photo_gallery.html.erb` | Swipeable photos with counter badge |
| `_property_details.html.erb` | Price, badges, address, directions, specs, description |
| `_floor_plans.html.erb` | Floor plan images |
| `_agent_card.html.erb` | Agent photo, name, tap-to-call, tap-to-email |
| `_lead_form.html.erb` | Already exists at `go/leads/_form.html.erb` |

Locals for each:
- `_photo_gallery`: `listing`
- `_property_details`: `listing`
- `_floor_plans`: `listing`
- `_agent_card`: `agent`, optional `label` (default "Your Agent")

---

## Step 2 — Rebuild Go listing view from partials

`app/views/go/listings/show.html.erb` becomes:

```erb
<%= render "go/shared/photo_gallery", listing: @listing %>
<%= render "go/shared/property_details", listing: @listing %>
<%= render "go/shared/floor_plans", listing: @listing %>

<% if @listing.primary_agent %>
  <%= render "go/shared/agent_card", agent: @listing.primary_agent %>
<% end %>

<div class="border-t border-gray-200 pt-6 mt-2">
  <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-4">Interested in this property?</h2>
  <%= render "go/leads/form", listing: @listing, agent: @listing.primary_agent %>
</div>

<% other_agents = @agents.reject { |a| a == @listing.primary_agent } %>
<% if other_agents.any? %>
  <div class="border-t border-gray-200 pt-6">
    <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-4">Also listed by</h2>
    <% other_agents.each do |agent| %>
      <%= render "go/shared/agent_card", agent: agent %>
    <% end %>
  </div>
<% end %>

<%= render "go/shared/share_button", title: @listing.address %>
```

Verify the listing page renders identically before and after.

---

## Step 3 — Create Go experience view + fix controller

**Controller:** `app/controllers/go/experiences_controller.rb`

```ruby
module Go
  class ExperiencesController < Go::BaseController
    def show
      @experience = Experience.find_by_param!(params[:id])
      @listing = @experience.listing
      @agent = @experience.default_agent
    end
  end
end
```

Remove `layout "player"` (inherits `public` from `Go::BaseController`).
Remove `render "play/players/experience"` (renders own view).

**View:** `app/views/go/experiences/show.html.erb`

```erb
<%= render "go/shared/photo_gallery", listing: @listing %>
<%= render "go/shared/property_details", listing: @listing %>
<%= render "go/shared/floor_plans", listing: @listing %>

<% if @agent %>
  <%= render "go/shared/agent_card", agent: @agent %>
<% end %>

<div class="border-t border-gray-200 pt-6 mt-2">
  <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-4">Interested in this property?</h2>
  <%= render "go/leads/form", listing: @listing, agent: @agent %>
</div>

<%= render "go/shared/share_button", title: @listing.address %>
```

Same partials as the listing page, but uses `@agent` (from
experience) instead of `@listing.primary_agent`.

---

## Step 4 — Update specs

Update `spec/requests/go/experiences_spec.rb` to verify:
- Renders with `public` layout (not `player`)
- Displays listing details
- Shows the experience's agent (not listing's primary agent)
- Renders the lead form

---

## Build Order

```
1. Extract shared partials from Go listing view
2. Rebuild listing view from partials — verify identical output
3. COMMIT

4. Create Go experience view + fix controller
5. Update specs
6. COMMIT
```

---

## Verification

1. `make test` — green
2. `/go/listings/:id` renders identically to before (partials)
3. `/go/experiences/:id` renders mobile landing page (not kiosk)
4. Experience page shows experience's agent, not listing's primary
5. Lead form works from both pages

---

## Files Changed

| File | Change |
|------|--------|
| `app/views/go/shared/_photo_gallery.html.erb` | New partial |
| `app/views/go/shared/_property_details.html.erb` | New partial |
| `app/views/go/shared/_floor_plans.html.erb` | New partial |
| `app/views/go/shared/_agent_card.html.erb` | New partial |
| `app/views/go/shared/_share_button.html.erb` | New partial |
| `app/views/go/listings/show.html.erb` | Rebuilt from partials |
| `app/views/go/experiences/show.html.erb` | New view |
| `app/controllers/go/experiences_controller.rb` | Remove kiosk render |
| `spec/requests/go/experiences_spec.rb` | Update assertions |
