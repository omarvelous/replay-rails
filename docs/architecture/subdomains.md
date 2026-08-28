# Subdomain Routing

RePlay uses 5 subdomains to separate concerns. Each maps to a Rails module with its own controllers, views, and layouts.

## Subdomain map

| Subdomain | Module | Layout | Auth | Purpose |
|-----------|--------|--------|------|---------|
| _(root)_ | `Marketing` | `marketing` | No | Public marketing pages + Go:: landing pages |
| `app` | `App` | `app` | Yes | Main application for brokerage users |
| `admin` | `Admin` | Administrate | Yes (admin) | Internal operations panel |
| `play` | `Play` | `player` | No | HTML playback rendered on screen devices |
| `api` | `Api` | — (JSON) | Token | Device communication API |

## Route structure

```ruby
# config/routes.rb

# Marketing — root domain (no subdomain)
constraints subdomain: "" do
  scope module: "marketing" do
    root "pages#home"
    get "/features", "/pricing", "/about"
  end

  # Consumer-facing landing pages
  namespace :go do
    resources :listings, only: :show
    resources :agents, only: :show
    resources :leads, only: :create
  end
end

# App — authenticated
constraints subdomain: "app" do
  scope module: "app" do
    root "dashboard#show"
    resources :listings, :agents, :screens, :playlists, ...
    # Nested: listing_agents, playlist_ads, screen_players, etc.
  end
end

# Admin — Administrate
constraints subdomain: "admin" do
  scope module: "admin", as: "admin" do
    root "dashboard#show"
    resources :accounts, :users, :listings, ...
  end
end

# API — JSON responses
constraints subdomain: "api" do
  scope module: "api" do
    resources :players, param: :token do
      resource :heartbeat, only: :create
      resources :impressions, only: :create
    end
  end
end

# Play — HTML for screens
constraints subdomain: "play" do
  scope module: "play" do
    resources :players, param: :token, only: [:new, :show]
  end
end

# Public (any subdomain)
get "/s/:token", to: "scans#show"
```

## Local development URLs

In development, subdomains resolve on `replay.localhost`:

| URL | Route |
|-----|-------|
| `replay.localhost:3000` | Marketing home |
| `app.replay.localhost:3000` | App dashboard |
| `admin.replay.localhost:3000` | Admin panel |
| `play.replay.localhost:3000/players/new` | Player pairing screen |
| `api.replay.localhost:3000/players` | Player API |
| `replay.localhost:3000/s/ABC123` | QR scan redirect |

`.localhost` domains resolve to `127.0.0.1` without `/etc/hosts` entries.

## Cross-subdomain auth

Sessions use a cookie with `domain: :all`, allowing a single login to work across `app`, `admin`, and other authenticated subdomains. The `resume_session` before_action runs globally so `Current.user` is available everywhere (even on unauthenticated pages).

## Controller inheritance

```
ApplicationController (Authentication concern, Pagy)
├── Marketing::PagesController (skip auth)
├── Go::ListingsController (skip auth)
├── Go::LeadsController (skip auth)
├── ScansController (skip auth)
├── App::BaseController (Action Policy, paper_trail whodunnit)
│   ├── App::ListingsController
│   ├── App::LeadsController
│   └── ... all app controllers
├── Admin::ApplicationController (Administrate)
│   ├── Admin::DashboardController
│   └── ... all admin controllers
├── Play::PlayersController (skip auth)
└── Api::PlayersController (token auth)
    ├── Api::Players::HeartbeatsController
    └── Api::Players::ImpressionsController
```
