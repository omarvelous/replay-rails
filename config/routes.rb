Rails.application.routes.draw do
  root "home#index"
  resources :accounts, only: [ :new, :create ]
  resources :sites do
    member do
      get :screens
    end
  end
  resources :screens do
    resource :screen_playlist, only: %i[ show new create destroy ]
  end
  resources :listings do
    resources :listing_agents
  end
  resources :agents do
    member do
      get :listings
    end
  end
  resources :ads do
    member do
      get :preview
      get :playlists
    end
  end
  resources :playlists do
    member do
      get :preview
      get :screens
    end
    resources :playlist_ads do
      collection do
        get :timeline
      end
    end
  end
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
