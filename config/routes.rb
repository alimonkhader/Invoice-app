Rails.application.routes.draw do
  root "home#index"

  resource :user_session, only: %i[create destroy]
  get "login", to: "user_sessions#new", as: :login

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
