Rails.application.routes.draw do
  devise_for :users,
             skip: [:registrations],
             controllers: {
               sessions: "users/sessions",
               passwords: "users/passwords"
             }

  devise_scope :user do
    get "login", to: "users/sessions#new", as: :login
    delete "logout", to: "devise/sessions#destroy", as: :logout
  end

  root "home#index"

  resource :settings, only: %i[show update], controller: :account_settings

  resources :plan_purchases, only: :show do
    member do
      post :verify
    end
  end

  resources :invoices do
    member do
      post :send_email
      get :share_whatsapp
    end
  end

  resources :customers
  resources :plans, only: [] do
    resources :registrations, only: %i[new create]
  end

  namespace :admin do
    resource :session, only: %i[create destroy]
    get "login", to: "sessions#new", as: :login
    resources :plans, only: %i[index create edit update]
    resources :accounts, only: :index
  end

  get "reports/purchases" => "reports#purchases", as: :purchase_reports
  get "reports/purchases/xlsx" => "reports#monthly_purchases_xlsx", as: :purchase_reports_xlsx
  get "up" => "rails/health#show", as: :rails_health_check
end
