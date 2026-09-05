# Plan: Coming Soon Gate

## Problem

Production is live at replaytv.co but the full marketing site
shouldn't be public yet. Need a minimal "Coming Soon" page that
gates the marketing site until launch, without affecting the app,
admin, player, or API subdomains.

## Approach

Route-level swap controlled by `ENV["COMING_SOON"]`. When set,
the marketing subdomain constraint only defines a root route
pointing to a standalone `ComingSoonController#show` and the
`POST /inquiries` endpoint for email capture. All other marketing
routes (features, pricing, about, demo, contact) don't exist.

When the env var is removed, the full marketing site routes are
defined as normal. Requires a restart to toggle (Render restarts
on env var change anyway).

---

## Implementation

### Routes

```ruby
constraints subdomain: "" do
  if ENV["COMING_SOON"] == "true"
    root "coming_soon#show", as: :marketing_root
    resources :inquiries, only: :create, module: "marketing"
  else
    scope module: "marketing" do
      root "pages#home", as: :marketing_root
      get "/features", to: "pages#features", as: :features
      # ... rest of marketing routes ...
    end
  end
end
```

### Controller

```ruby
class ComingSoonController < ApplicationController
  layout false

  def show
  end
end
```

No layout, no auth, no tenant scoping. Renders an inline ERB
template with self-contained HTML and CSS.

### View

`app/views/coming_soon/show.html.erb` — a complete standalone
HTML page (no layout inheritance):

- Full `<!DOCTYPE html>` document with inline `<style>` tag
- RePlay logo (SVG, centered)
- "Coming Soon" headline
- One-liner: "Digital signage for real estate brokerages"
- Email capture form → `POST /inquiries` with
  `inquiry_type: "coming_soon"`
- "Notify me" CTA button
- Minimal dark theme matching the Bold direction
- Fully responsive, no external CSS dependencies
- No nav, no footer, no links to other pages

### Inquiry Type

Add `"coming_soon"` to `Inquiry::TYPES` so email signups are
trackable separately in the admin panel.

---

## What Changes

| Route | Coming soon mode | Normal mode |
|-------|-----------------|-------------|
| `/` | ComingSoonController#show | Marketing::Pages#home |
| `/features` | 404 | Marketing::Pages#features |
| `/pricing` | 404 | Marketing::Pages#pricing |
| `/about` | 404 | Marketing::Pages#about |
| `/demo` | 404 | Marketing::Pages#demo |
| `/contact` | 404 | Marketing::Pages#contact |
| `POST /inquiries` | Works (email capture) | Works (demo/contact forms) |

## What's Unaffected

- `app.replaytv.co` — full app
- `admin.replaytv.co` — admin panel
- `play.replaytv.co` — player
- `api.replaytv.co` — API
- `/up` — health check
- `/s/:token` — QR scans
- `rply.tv` — short domain

---

## Toggling

- **Enable:** Set `COMING_SOON=true` in Render production env vars
- **Disable:** Remove the env var. Full marketing site appears.
- Render restarts on env var change — no code deploy needed.

---

## Build Order

1. Add `coming_soon` to `Inquiry::TYPES`
2. Create `ComingSoonController` (layout false)
3. Create standalone view with inline CSS
4. Update routes with conditional swap
5. Spec: coming soon page renders
6. Set `COMING_SOON=true` in Render production env vars
