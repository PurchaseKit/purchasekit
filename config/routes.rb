PurchaseKit::Pay::Engine.routes.draw do
  resources :purchases, only: [:create]
  resource :webhooks, only: [:create]

  namespace :purchase do
    resources :intents, only: [], param: :uuid do
      resource :completions, only: [:create]
    end
  end
end
