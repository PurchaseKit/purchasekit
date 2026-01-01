PurchaseKit::Engine.routes.draw do
  resource :webhooks, only: :create
  resources :purchases, only: :create

  # Demo mode only - Xcode StoreKit testing completion endpoint
  post "purchase/completions/:id", to: "purchase/completions#create"
end
