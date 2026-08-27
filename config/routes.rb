Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # ---------------------------------------------------------------
  # Marketing — root domain (no subdomain)
  # ---------------------------------------------------------------
  constraints subdomain: "" do
    scope module: "marketing" do
      root "pages#home", as: :marketing_root
      get "/features", to: "pages#features", as: :features
      get "/pricing",  to: "pages#pricing",  as: :pricing
      get "/about",    to: "pages#about",    as: :about
    end

    # Public destination pages (consumer-facing, marketing domain)
    namespace :go do
      resources :listings, only: :show
      resources :agents, only: :show
      resources :leads, only: :create
    end
  end

  # ---------------------------------------------------------------
  # App — app subdomain (authenticated)
  # ---------------------------------------------------------------
  constraints subdomain: "app" do
    scope module: "app" do
      root "home#index", as: :app_root
      resources :accounts, only: %i[ new create ]
      resources :sites
      resources :screens do
        resource :screen_playlist, only: %i[ new create destroy ]
        resource :screen_player, only: %i[ new create destroy ]
      end
      resources :listings do
        resources :listing_agents, only: %i[ new create edit update destroy ]
      end
      resources :agents
      namespace :ads do
        resources :listing_ads,    only: %i[ new create edit update ]
        resources :collection_ads, only: %i[ new create edit update ]
        resources :agent_ads,      only: %i[ new create edit update ]
        resources :brand_ads,      only: %i[ new create edit update ]
      end
      resources :ads, only: %i[ index new show edit update destroy ] do
        member { get :preview }
      end
      resources :playlists do
        member { get :preview }
        resources :playlist_ads, only: %i[ new create edit update destroy ]
      end
      resources :qr_codes, only: %i[ index show ]
      resources :leads, only: %i[ index show update ] do
        resources :lead_agents, only: %i[ new create ]
      end
      resources :users, only: %i[ index show ]
      resources :invites, param: :token, only: %i[ index new create show update destroy ]
      resource :session
      resources :passwords, param: :token
    end
  end

  # ---------------------------------------------------------------
  # Admin — admin subdomain (internal ops)
  # ---------------------------------------------------------------
  constraints subdomain: "admin" do
    scope module: "admin", as: "admin" do
      root "dashboard#show", as: :root
      resources :accounts
      resources :users
      resources :sites
      resources :players
      resources :screens
      resources :listings
      resources :agents
      resources :ads
      resources :playlists
      resources :qr_codes
      resources :qr_scans
      resources :leads
      resources :lead_agents
      resources :account_users
      resources :invites
    end
  end

  # ---------------------------------------------------------------
  # API — api subdomain (JSON, device communication)
  # ---------------------------------------------------------------
  constraints subdomain: "api" do
    scope module: "api" do
      resources :players, param: :token, only: [ :create, :show ] do
        scope module: "players" do
          resource :heartbeat, only: [ :create ]
          resources :impressions, only: [ :create ]
        end
      end
    end
  end

  # ---------------------------------------------------------------
  # Play — play subdomain (HTML, visual content for screens)
  # ---------------------------------------------------------------
  constraints subdomain: "play" do
    scope module: "play" do
      resources :players, param: :token, only: [ :new, :show ]
    end
  end

  # ---------------------------------------------------------------
  # Public (any subdomain)
  # ---------------------------------------------------------------
  get "/s/:token", to: "scans#show", as: :qr_scan

  get "up" => "rails/health#show", as: :rails_health_check
end
