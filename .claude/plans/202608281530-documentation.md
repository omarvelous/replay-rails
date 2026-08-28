# Plan: Documentation v3

## What changed from v2

- **Content lives in `app/views/docs/`** — standard Rails views, not a custom `docs/user/` directory with manual file loading
- **`Docs` module** instead of `Marketing` — standalone namespace, not coupled to marketing pages
- **Pure ERB** — no Commonmarker gem, no markdown pipeline. Tailwind `prose` + component partials make ERB content read cleanly
- **Metadata in YAML config** — single `config/docs.yml` instead of per-file frontmatter. Easier to maintain, query, and reorder
- **No versioning/staleness** — dropped `updated_at`, `tracks`, and staleness Rake task. Not needed pre-launch with a small team
- **Auth-gatable** — `Docs` module can add auth later without restructuring

---

## Architecture

### Routing

Docs live on the marketing subdomain (public) at `/docs`. The `Docs` module is its own namespace — not nested under Marketing.

```ruby
# config/routes.rb
constraints subdomain: "" do
  # Marketing pages...

  # Documentation — own module, public
  scope module: "docs" do
    get "/docs",       to: "pages#index", as: :docs
    get "/docs/*slug", to: "pages#show",  as: :doc
  end
end
```

To make docs internal later, move the routes under `constraints subdomain: "app"` and add auth. No other changes needed.

### Controller

```ruby
# app/controllers/docs/pages_controller.rb
module Docs
  class PagesController < ApplicationController
    skip_before_action :require_authentication
    layout "docs"

    def index
      @categories = DocsManifest.categories
    end

    def show
      @page = DocsManifest.find(params[:slug])
      raise ActionController::RoutingError, "Not Found" unless @page

      render template: "docs/pages/#{@page[:template]}"
    end
  end
end
```

The controller is thin — it looks up metadata from the manifest and renders the matching view template. No file reading, no inline rendering, no markdown conversion.

### Manifest

A single YAML file holds all doc metadata. Replaces per-file frontmatter.

```yaml
# config/docs.yml
categories:
  - name: Getting Started
    pages:
      - title: Quick Start Guide
        slug: getting-started
        template: getting_started
        description: Go from signup to a live screen in 15 minutes


  - name: Content
    pages:
      - title: Managing Listings
        slug: listings
        template: listings
        description: Add, edit, and organize your property listings

      - title: Creating Ads
        slug: ads/overview
        template: ads/overview
        description: "The four ad types: listing, collection, agent, and brand"

      - title: Listing Ads
        slug: ads/listing-ads
        template: ads/listing_ads
        description: Create ads from your property listings

      - title: Building Playlists
        slug: playlists
        template: playlists
        description: Arrange ads into playlists for your screens


  - name: Screens & Players
    pages:
      - title: Managing Screens
        slug: screens
        template: screens
        description: Set up screens and assign playlists

      - title: Pairing a Player
        slug: player-pairing
        template: player_pairing
        description: Connect a player device to your screen


  - name: Leads & QR Codes
    pages:
      - title: QR Codes
        slug: qr-codes
        template: qr_codes
        description: How QR codes work and scan tracking

      - title: Lead Capture
        slug: leads
        template: leads
        description: The QR-to-lead pipeline and agent assignment


  - name: Team
    pages:
      - title: Managing Your Team
        slug: team
        template: team
        description: Invite users, assign roles, manage access

      - title: Agents
        slug: agents
        template: agents
        description: Agent profiles and listing assignments

```

### DocsManifest

A simple loader class — reads the YAML once, provides lookup methods.

```ruby
# app/models/docs_manifest.rb
class DocsManifest
  MANIFEST_PATH = Rails.root.join("config/docs.yml")

  class << self
    def categories
      manifest["categories"]
    end

    def find(slug)
      all_pages.find { |p| p[:slug] == slug }
    end

    def all_pages
      categories.flat_map do |cat|
        cat["pages"].map do |page|
          {
            title: page["title"],
            slug: page["slug"],
            template: page["template"],
            description: page["description"],
            category: cat["name"]
          }
        end
      end
    end

    private

    def manifest
      @manifest ||= YAML.safe_load_file(MANIFEST_PATH)
    end
  end
end
```

### Views

Content lives in `app/views/docs/pages/` as standard ERB templates.

```
app/views/docs/
├── pages/
│   ├── getting_started.html.erb
│   ├── listings.html.erb
│   ├── agents.html.erb
│   ├── ads/
│   │   ├── overview.html.erb
│   │   ├── listing_ads.html.erb
│   │   ├── collection_ads.html.erb
│   │   ├── agent_ads.html.erb
│   │   └── brand_ads.html.erb
│   ├── playlists.html.erb
│   ├── screens.html.erb
│   ├── player_pairing.html.erb
│   ├── qr_codes.html.erb
│   ├── leads.html.erb
│   └── team.html.erb
├── shared/
│   ├── _callout.html.erb
│   ├── _steps.html.erb
│   ├── _screenshot.html.erb
│   └── _related.html.erb
└── _sidebar.html.erb
```

### Layout

Docs get their own layout — marketing nav with a sidebar for doc navigation.

```erb
<%# app/views/layouts/docs.html.erb %>
<!DOCTYPE html>
<html lang="en" data-theme="light">
  <head>
    <title><%= @page ? "#{@page[:title]} — RePlay Docs" : "RePlay Docs" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="bg-white min-h-screen">
    <!-- Marketing nav (shared) -->
    <nav class="border-b border-gray-200">
      <div class="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
        <%= link_to marketing_root_path do %>
          <span class="text-lg font-bold tracking-tight">Re<b class="text-indigo-600">Play</b></span>
        <% end %>
        <div class="flex items-center gap-4 text-sm">
          <%= link_to "Docs", docs_path, class: "font-semibold text-indigo-600" %>
          <%= link_to "Log in", new_session_url(subdomain: "app"), class: "text-gray-600 hover:text-gray-900" %>
        </div>
      </div>
    </nav>

    <div class="max-w-6xl mx-auto px-6 py-10 flex gap-10">
      <!-- Sidebar -->
      <aside class="hidden lg:block w-56 shrink-0">
        <%= render "docs/sidebar" %>
      </aside>

      <!-- Content -->
      <article class="prose prose-indigo max-w-none flex-1 min-w-0">
        <%= yield %>
      </article>
    </div>
  </body>
</html>
```

### Component partials

Small, focused partials in `app/views/docs/shared/`:

**Callout** — tip / warning / info boxes:
```erb
<%# app/views/docs/shared/_callout.html.erb %>
<% colors = { "tip" => "bg-green-50 border-green-200 text-green-800",
              "warning" => "bg-amber-50 border-amber-200 text-amber-800",
              "info" => "bg-blue-50 border-blue-200 text-blue-800" } %>
<div class="not-prose rounded-lg border p-4 my-4 text-sm <%= colors[type] %>">
  <p class="font-semibold capitalize mb-1"><%= type %></p>
  <%= yield %>
</div>
```

**Steps** — numbered step list with visual styling:
```erb
<%# app/views/docs/shared/_steps.html.erb %>
<div class="not-prose my-6 space-y-4 pl-8 border-l-2 border-indigo-200">
  <%= yield %>
</div>
```

**Screenshot** — image with caption:
```erb
<%# app/views/docs/shared/_screenshot.html.erb %>
<figure class="not-prose my-6">
  <%= image_tag src, class: "rounded-lg ring-1 ring-gray-200 shadow-sm w-full" %>
  <% if local_assigns[:caption] %>
    <figcaption class="text-sm text-gray-500 text-center mt-2"><%= caption %></figcaption>
  <% end %>
</figure>
```

**Related** — links to related pages:
```erb
<%# app/views/docs/shared/_related.html.erb %>
<div class="not-prose mt-8 p-4 bg-gray-50 rounded-lg">
  <p class="text-sm font-semibold text-gray-700 mb-2">Related</p>
  <ul class="space-y-1">
    <% pages.each do |slug, title| %>
      <li><%= link_to title, doc_path(slug), class: "text-sm text-indigo-600 hover:text-indigo-500" %></li>
    <% end %>
  </ul>
</div>
```

---

## Developer docs

Developer docs stay in the repo as plain markdown — no app rendering needed. Read on GitHub or locally.

```
docs/
├── onboarding.md
├── architecture/
│   ├── overview.md
│   ├── domain-model.md
│   ├── subdomains.md
│   ├── ad-templates.md
│   ├── lead-capture.md
│   ├── qr-codes.md
│   ├── player-pairing.md
│   └── signage-css.md
├── api/
│   ├── player-api.md
│   └── scan-api.md
├── testing.md
└── deployment.md
```

These are written in Phase 1 — no app code changes needed.

---

## Gem dependencies

```ruby
# None — pure ERB, no markdown gem needed
```

Tailwind typography plugin — add to `app/assets/tailwind/application.css`:

```css
@plugin "@tailwindcss/typography";
```

Install:
```bash
yarn add @tailwindcss/typography
# or if using bundled Tailwind:
# Already available via CDN/gem
```

---

## Build order

### Phase 0 — Repo reorg

Consolidate scattered docs under `.claude/` and clean up `tmp/`.

1. Move `agent-os/standards/` → `.claude/standards/`
2. Move `agent-os/product/` → `.claude/product/`
3. Move `agent-os/specs/` → `.claude/specs/`
4. Delete `agent-os/` directory
5. Update CLAUDE.md paths to reference `.claude/standards/`
6. Move `tmp/plan-roadmap.md` → `.claude/product/roadmap.md`
7. Update `.claude/product/roadmap.md` — mark RBAC, user invites, rate limiting, analytics, pagination, audit trail as shipped. Adjust tiers and execution order.
8. Delete superseded `tmp/` plans: `plan-documentation.md`, `plan-documentation-v2.md`, `plan-metrics.md`
9. Clean up `tmp/notes.md`, `tmp/analysis-branding.md` — delete if stale, move if useful

### Phase 1 — Developer docs (repo only, no app changes)

10. `docs/onboarding.md` — new dev first day
11. `docs/architecture/overview.md` — high-level architecture
12. `docs/architecture/domain-model.md` — Mermaid ER diagram + model table
13. `docs/architecture/subdomains.md` — subdomain routing
14. `docs/architecture/ad-templates.md` — Ads:: namespace, delegated types
15. `docs/architecture/lead-capture.md` — lead pipeline, attribution
16. `docs/architecture/qr-codes.md` — scan flow, qualified scans
17. `docs/architecture/player-pairing.md` — three models, heartbeat
18. `docs/architecture/signage-css.md` — cqw units, custom properties
19. `docs/api/player-api.md` — play + api subdomain endpoints
20. `docs/api/scan-api.md` — `/s/:token` redirect logic
21. `docs/testing.md` — TDD workflow, SimpleCov, thresholds

### Phase 2 — In-app docs infrastructure (TDD)

22. RED: Request spec for `GET /docs` — returns 200, no auth required
23. RED: Request spec for `GET /docs/getting-started` — returns 200, renders content
24. RED: Request spec for `GET /docs/nonexistent` — returns 404
25. GREEN: `DocsManifest` model with `categories`, `find`, `all_pages`
26. GREEN: `Docs::PagesController` with `index` and `show` actions
27. GREEN: Routes under marketing subdomain
28. GREEN: `docs` layout with nav, sidebar, prose content area
29. GREEN: Sidebar partial rendering categories + pages from manifest
30. GREEN: Component partials: `_callout`, `_steps`, `_screenshot`, `_related`
31. Add `@tailwindcss/typography` plugin

### Phase 3 — User doc content

32. `config/docs.yml` manifest with all pages
33. `getting_started.html.erb` — signup to live screen in 15 minutes
34. `listings.html.erb` — managing property listings
35. `agents.html.erb` — agent profiles and assignments
36. `ads/overview.html.erb` — the four ad types
37. `ads/listing_ads.html.erb` — creating listing ads
38. `playlists.html.erb` — building and ordering playlists
39. `screens.html.erb` — managing screens, assigning playlists
40. `player_pairing.html.erb` — step-by-step pairing
41. `qr_codes.html.erb` — how QR codes work
42. `leads.html.erb` — QR-to-lead pipeline, agent assignment
43. `team.html.erb` — invites, roles, access management

### Phase 4 — Polish

44. App sidebar link to docs (cross-subdomain)
45. `docs/deployment.md` — Kamal, Docker, env vars

---

## Content approach

- **Task-oriented** — "How do I create a listing ad?" not "The Ad model supports delegated types..."
- **Visual** — screenshots of each step (text first, added iteratively)
- **Progressive disclosure** — getting started → daily tasks → advanced
- **No jargon** — "ad type" not "delegated type", "pairing code" not "token"
- **ERB reads like prose** — Tailwind `prose` handles typography, component partials handle visual structure

---

## What's deferred

- **Staleness tracking** — `updated_at` + `tracks` fields in manifest, Rake task to flag stale docs. Add when doc surface area grows
- **Search** — client-side search (Pagefind or similar)
- **Video tutorials** — requires production environment + recording
- **Screenshots** — added iteratively, text-first for now
- **API docs for external consumers** — player API is internal
- **Localization** — docs in other languages
- **PDF export** — printable versions
