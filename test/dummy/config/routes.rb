Rails.application.routes.draw do
  mount PurchaseKit::Engine, at: "/purchasekit"

  get "up" => "rails/health#show", :as => :rails_health_check

  root to: proc { [200, {}, ["OK"]] }
end
