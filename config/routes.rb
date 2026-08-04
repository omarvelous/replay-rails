Rails.application.routes.draw do
  root "home#index"
  resources :accounts, only: [ :new, :create ]
  resources :sites do
    resources :screens
  end
  resources :screens, only: [] do
    resource :playlist, controller: "screens/playlist", only: %i[ new create destroy ]
  end
  resources :listings do
    resources :agents, controller: "listings/agents", only: %i[ index new create edit update destroy ]
  end
  resources :agents do
    resources :listings, controller: "agents/listings", only: %i[ index destroy ]
  end
  resources :ads do
    member do
      get :preview
    end
    resources :playlists, controller: "ads/playlists", only: %i[ index destroy ]
  end
  resources :playlists do
    member do
      get :preview
    end
    resources :ads, controller: "playlists/ads", only: %i[ index new create edit update destroy ]
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
