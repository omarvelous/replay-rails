# Plan: Marketing Site & Subdomain Architecture (executed)

_Final version. Supersedes all `plan-marketing-site-*.md` files in tmp/._

## Status: Phases 1-5 complete

399 specs, 0 failures. 97.05% line coverage, 81.16% branch coverage.

---

## Subdomain map

| Subdomain | Domain (dev) | Purpose | Auth | Layout |
|-----------|-------------|---------|------|--------|
| (root) `""` | `replay.localhost` | Marketing + `/go/` public landing pages | None | `marketing` |
| `app` | `app.replay.localhost` | Authenticated product | User session | `app` |
| `play` | `play.replay.localhost` | Device API (register, status, play, heartbeat) | Bearer token | `player` |
| any | any | `/s/:token` scan redirect | None | redirect only |
| `admin` | `admin.replay.localhost` | Internal admin (not yet built) | User + admin | `admin` |

**Auth lives entirely on `app`.** Login, signup, password reset, session
management — all on the app subdomain. Marketing is fully public. Admin
reuses the app session (cookie shared via `domain: :all`).

---

## What we solved during implementation

### 1. Dual root routes
Named roots: `marketing_root_path` and `app_root_path`. Every reference
to `root_path` / `root_url` replaced with the explicit named root.

### 2. Auth redirects cross subdomain
`after_authentication_url` uses `app_root_path` (relative path, not URL).
Avoids `OpenRedirectError` when the request originates from a different subdomain.

### 3. Session cookies across subdomains
```ruby
# config/application.rb
config.session_store :cookie_store, key: "_replay_session", domain: :all
```

### 4. TLD configuration
`.localhost` has TLD length 1. Set in all environments:
```ruby
config.action_dispatch.tld_length = 1
```

### 5. Test hosts
- Request specs default to `host! "app.replay.localhost"` via `rails_helper.rb`
- Marketing specs override with `host! "replay.localhost"`
- Player API specs override with `host! "play.replay.localhost"`
- `/go/` specs override with `host! "replay.localhost"`

### 6. System specs and Docker DNS
Docker's embedded DNS cannot resolve subdomain aliases (e.g. `app.web`).
System specs converted to request specs — auth flows already covered by
request specs with `host!`. Re-add system specs when testing JS-dependent
features once Docker DNS is solved (dnsmasq container or similar).

### 7. Partial path references
When views moved to `app/views/app/`, all render calls updated:
- `render "shared/sidebar"` → `render "app/shared/sidebar"`
- `render "ads/layouts/#{ad.layout}"` → `render "app/ads/layouts/#{ad.layout}"`
- `render "sites/site_card"` → `render "app/sites/site_card"`

Layout file (`layouts/app.html.erb`) also uses `app/shared/` paths.

### 8. Cross-subdomain redirects
Scans controller redirects to `/go/listings/:id` on the marketing subdomain:
```ruby
redirect_to polymorphic_url([:go, qr.destination_record], subdomain: ""), allow_other_host: true
```

### 9. Player API URL changes
Player routes moved from `/player/*` (any subdomain) to root paths on `play` subdomain.
Device JS updated: `/status`, `/`, `/heartbeat` (no `/player` prefix).

---

## Routes (as implemented)

```ruby
Rails.application.routes.draw do
  # Marketing — root domain (no subdomain)
  constraints subdomain: "" do
    scope module: "marketing" do
      root "pages#home", as: :marketing_root
      get "/features", to: "pages#features", as: :features
      get "/pricing",  to: "pages#pricing",  as: :pricing
      get "/about",    to: "pages#about",    as: :about
    end
    namespace :go do
      resources :listings, only: :show
    end
  end

  # App — app subdomain (authenticated)
  constraints subdomain: "app" do
    scope module: "app" do
      root "home#index", as: :app_root
      # ... all app resources
    end
  end

  # Play — play subdomain (device API)
  constraints subdomain: "play" do
    post "/register",  to: "player_api#register"
    get  "/status",    to: "player_api#status"
    get  "/",          to: "player_api#play", as: :play_root
    post "/heartbeat", to: "player_api#heartbeat"
    post "/impression", to: "player_api#impression"
  end

  # Public (any subdomain)
  get "/s/:token", to: "scans#show", as: :qr_scan
  get "up" => "rails/health#show", as: :rails_health_check
end
```

---

## Directory structure (as implemented)

```
app/controllers/
├── application_controller.rb
├── concerns/authentication.rb
├── marketing/
│   ├── base_controller.rb
│   └── pages_controller.rb
├── app/
│   ├── base_controller.rb
│   ├── home_controller.rb
│   ├── sites_controller.rb
│   ├── screens_controller.rb
│   ├── ... (all app controllers)
│   └── ads/ (type controllers)
├── player_api_controller.rb
├── scans_controller.rb
└── go/listings_controller.rb

app/views/
├── layouts/
│   ├── app.html.erb
│   ├── marketing.html.erb
│   ├── player.html.erb
│   └── public.html.erb
├── app/ (all app views)
├── marketing/pages/
├── player_api/
└── go/listings/
```

---

## Environment configuration

```ruby
# config/application.rb
config.session_store :cookie_store, key: "_replay_session", domain: :all

# development.rb
config.action_dispatch.tld_length = 1
config.action_controller.default_url_options = { host: "replay.localhost", port: 3000 }
config.action_mailer.default_url_options = { host: "app.replay.localhost", port: 3000 }

# test.rb
config.action_dispatch.tld_length = 1
config.action_mailer.default_url_options = { host: "app.replay.localhost" }

# production.rb
config.action_dispatch.tld_length = 1
config.action_controller.default_url_options = { host: "replay.com", protocol: "https" }
config.action_mailer.default_url_options = { host: "app.replay.com", protocol: "https" }
```

---

## What's remaining

### Phase 6 — Sign-up flow
- `Marketing::SignupsController` on marketing subdomain
- POST stays on marketing domain (same-origin CSRF)
- Redirect to `app_root_url(subdomain: "app")` after creation

### Phase 7 — Marketing content + polish
- Homepage, features, pricing, about (placeholder views exist, need real content)
- Contact form: `Marketing::Inquiry` model
- SEO: meta tags, OG tags, sitemap

### Phase 8 — Blog
- Markdown+ERB posts, `Marketing::PostsController`

### Phase 9 — Admin subdomain (see plan-admin.md)

### Docker DNS for system specs
- Add dnsmasq container for subdomain resolution
- Re-add browser-based system specs for JS-dependent features
