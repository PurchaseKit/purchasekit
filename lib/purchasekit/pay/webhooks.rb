module PurchaseKit
  module Pay
    module Webhooks
      autoload :Base, "purchasekit/pay/webhooks/base"
      autoload :SubscriptionCreated, "purchasekit/pay/webhooks/subscription_created"
      autoload :SubscriptionUpdated, "purchasekit/pay/webhooks/subscription_updated"
      autoload :SubscriptionCanceled, "purchasekit/pay/webhooks/subscription_canceled"
      autoload :SubscriptionExpired, "purchasekit/pay/webhooks/subscription_expired"
    end
  end
end
