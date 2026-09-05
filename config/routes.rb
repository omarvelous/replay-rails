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
      get "/demo",     to: "pages#demo",     as: :demo
      get "/contact",  to: "pages#contact",  as: :contact
      resources :inquiries, only: :create
    end

    # Documentation
    scope module: "docs" do
      get "/docs",       to: "pages#index", as: :docs
      get "/docs/*slug", to: "pages#show",  as: :doc
    end

    # Consumer-facing landing pages
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
      root "dashboard#show", as: :app_root

      # Auth
      resource :session
      resources :passwords, param: :token
      resources :accounts, only: %i[new create]

      # Content
      resources :listings do
        resources :listing_agents, only: %i[new create edit update destroy]
      end
      resources :agents
      namespace :ads do
        resources :listing_ads,    only: %i[new create edit update]
        resources :collection_ads, only: %i[new create edit update]
        resources :agent_ads,      only: %i[new create edit update]
        resources :brand_ads,      only: %i[new create edit update]
      end
      resources :ads, only: %i[index new show edit update destroy] do
        member { get :preview }
      end

      # Experiences
      resources :experiences

      # Playback
      resource :pair, only: %i[show create], controller: "pairings"
      resources :sites
      resources :screens do
        resource :screen_content, only: %i[new create destroy]
        resource :screen_player, only: %i[new create destroy]
      end
      resources :playlists do
        member { get :preview }
        resources :playlist_ads, only: %i[new create edit update destroy]
      end

      # Engagement
      resources :qr_codes, only: %i[index show] do
        resources :scans, controller: "qr_scans", only: :index
      end
      resources :leads, only: %i[index show update] do
        resources :lead_agents, only: %i[new create]
      end

      # Team
      resources :users, only: %i[index show] do
        resources :account_users, only: %i[index create destroy]
      end
      resources :invites, param: :token, only: %i[index new create show update destroy] do
        member { post :resend }
      end
    end
  end

  # ---------------------------------------------------------------
  # Admin — admin subdomain (internal ops)
  # ---------------------------------------------------------------
  constraints subdomain: "admin" do
    scope module: "admin", as: "admin" do
      root "dashboard#show", as: :root

      # Content
      resources :accounts
      resources :listings
      resources :agents
      resources :ads

      # Playback
      resources :sites
      resources :screens
      resources :players
      resources :playlists

      # Engagement
      resources :qr_codes
      resources :qr_scans
      resources :leads
      resources :lead_agents

      # Team
      resources :users
      resources :account_users
      resources :invites

      # Inquiries
      resources :inquiries

      # Audit
      namespace :paper_trail do
        resources :versions, only: :index
      end
    end
  end

  # ---------------------------------------------------------------
  # API — api subdomain (JSON, device communication)
  # ---------------------------------------------------------------
  constraints subdomain: "api" do
    scope module: "api" do
      resources :players, param: :token, only: %i[create show] do
        scope module: "players" do
          resource :heartbeat, only: :create
          resources :impressions, only: :create
          resource :pairing_code, only: :create
        end
      end
    end
  end

  # ---------------------------------------------------------------
  # Play — play subdomain (HTML, visual content for screens)
  # ---------------------------------------------------------------
  constraints subdomain: "play" do
    scope module: "play" do
      root "players#landing", as: :play_root
      resources :players, param: :token, only: %i[new show]
    end
  end

  # ---------------------------------------------------------------
  # Public (any subdomain)
  # ---------------------------------------------------------------
  get "/s/:token", to: "scans#show", as: :qr_scan

  get "up" => "rails/health#show", as: :rails_health_check
end
