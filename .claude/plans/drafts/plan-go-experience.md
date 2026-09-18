# Plan: Go Experience Page

**Created:** 2026-09-18
**Status:** Draft
**Branch:** TBD

## Problem

`Go::ExperiencesController#show` renders `play/players/experience` —
a kiosk template designed for paired screen devices. This is wrong.
The Go experience is a consumer-facing landing page someone visits
on their phone after scanning a QR code or tapping an NFC tag. It
should feel like the Go listing page, not a kiosk.

The cross-module render was a shortcut. The two are fundamentally
different products:

| | Play Experience | Go Experience |
|---|---|---|
| **Audience** | Passersby at a shared screen | Individual on their own phone |
| **Layout** | Full-screen kiosk, no chrome | Mobile-optimized public page |
| **Interaction** | Touch gallery, idle/attract mode | Scroll, tap-to-call, fill form |
| **Device plumbing** | Heartbeat, manifest, ActionCable | None |
| **Lead capture** | QR handoff to phone | Inline lead form |
| **Agent contact** | Display only | Tap-to-call, tap-to-email |
| **Layout file** | `player` | `public` (or future `go`) |

## Design

The Go experience page should follow the same pattern as
`go/listings/show.html.erb` — a mobile-first landing page with:

- Swipeable photo gallery (CSS scroll-snap)
- Property details (price, address, specs, description)
- Agent card with tap-to-call and tap-to-email
- Floor plans section
- Lead capture form
- Get directions link
- Share button

Essentially the Go listing page, but entered via an Experience URL
rather than a Listing URL. The experience provides the listing +
agent context.

### Controller

```ruby
module Go
  class ExperiencesController < Go::BaseController
    def show
      @experience = Experience.find_by_param!(params[:id])
      @listing = @experience.listing
      @agent = @experience.default_agent
      @agents = [@agent].compact
    end
  end
end
```

### View

`app/views/go/experiences/show.html.erb` — its own template, not
a cross-module render. Can share partials with Go listings if there's
overlap (photo gallery, agent card, lead form), but the page is
owned by Go, not Play.

### Shared Go partials (optional)

If the Go listing and Go experience pages share significant markup,
extract into `app/views/go/shared/` partials:
- `_photo_gallery.html.erb`
- `_agent_card.html.erb`
- `_property_details.html.erb`
- `_lead_form.html.erb` (already exists as `go/leads/_form.html.erb`)

## Execution

### Step 1 — Create Go::BaseController
(If not already done from cleanup plan)

### Step 2 — Create Go experience view
- `app/views/go/experiences/show.html.erb`
- Mobile-first layout following Go listing page pattern
- Photo gallery, details, agent card, lead form, directions, share

### Step 3 — Update controller
- Remove cross-module render
- Set @listing, @agent from experience
- Use `public` layout (via Go::BaseController)

### Step 4 — Extract shared Go partials (if warranted)
- Compare Go listing and Go experience views
- Extract common sections into `go/shared/` partials

### Step 5 — Ship
- `make lint`, `make test`
- Push, create PR

## Out of Scope

- Play kiosk template changes (stays as-is for screen devices)
- Go layout redesign (use `public` layout for now)
