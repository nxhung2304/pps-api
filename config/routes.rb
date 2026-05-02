Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"

  post "auth/register", to: "auth#register"
  post "auth/login", to: "auth#login"

  namespace :api do
    namespace :v1 do
      resources :events, only: [ :create ]
    end
  end
end
