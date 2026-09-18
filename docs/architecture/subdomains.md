# Subdomain Routing

RePlay uses 5 subdomains to separate concerns. Each maps to a Rails module with its own controllers, views, and layouts.

## Subdomain map

| Subdomain | Module | Layout | Auth | Purpose |
|-----------|--------|--------|------|---------|
| _(root)_ | `Marketing` | `marketing` | No | Public marketing pages + Go:: landing pages |
| `app` | `App` | `app` | Yes | Main application for brokerage users |
| `admin` | `Admin` | Administrate | Yes (admin) | Internal operations panel |
| `play` | `Play` | `player` | Cookie | HTML playback rendered on screen devices |
| `api` | `Api` | — (JSON) | Cookie | Native app API (future use) |

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
    resources :experiences, only: :show
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

# Play — HTML for screens (self-contained, cookie auth)
constraints subdomain: "play" do
  scope module: "play" do
    root "players#show"           # redirects to /player/new if no session
    resource :player, only: [:new, :create, :show] do
      resource :heartbeat, only: :create
      resource :manifest, only: :show
      resource :pairing_code, only: :create
      resource :session, only: :create
    end
  end
end

# API — JSON for native apps (future)
constraints subdomain: "api" do
  scope module: "api" do
    namespace :v1 do
      resource :player, only: [:create, :show] do
        resource :heartbeat, only: :create
        resource :manifest, only: :show
        resource :pairing_code, only: :create
      end
    end
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
| `play.replay.localhost:3000` | Player (root → pairing if no session) |
| `play.replay.localhost:3000/player/new` | Player pairing screen |
| `play.replay.localhost:3000/player` | Player playback |
| `replay.localhost:3000/s/ABC123` | QR scan redirect |

`.localhost` domains resolve to `127.0.0.1` without `/etc/hosts` entries.

## Cross-subdomain auth

Sessions use a cookie with `domain: :all`, allowing a single login to work across `app`, `admin`, and other authenticated subdomains. The `resume_session` before_action runs globally so `Current.user` is available everywhere (even on unauthenticated pages).

Player sessions use a separate `player_session_id` signed cookie scoped to the `play` subdomain.

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
├── Play::PlayersController (cookie auth)
│   ├── Play::Players::HeartbeatsController
│   ├── Play::Players::ManifestsController
│   ├── Play::Players::PairingCodesController
│   └── Play::Players::SessionsController
└── Api::V1::PlayersController (cookie auth)
    ├── Api::V1::Players::HeartbeatsController
    ├── Api::V1::Players::ManifestsController
    └── Api::V1::Players::PairingCodesController
```
