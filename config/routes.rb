Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  # API routes
  namespace :api do
    namespace :v1 do
      # Users routes
      resources :users, only: [ :index, :show, :create ] do
        # Sleep records routes
        resources :sleep_records, only: [ :index, :show ] do
          collection do
            post :clock_in
            get :following_sleep_records
          end
        end

        # User following routes
        resources :followings, controller: "user_followings", only: [ :index, :create, :destroy ] do
          collection do
            get :followers
          end
        end
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
