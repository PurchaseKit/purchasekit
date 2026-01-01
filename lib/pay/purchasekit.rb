module Pay
  module Purchasekit
    class Error < Pay::Error
    end

    module_function

    def enabled?
      true
    end

    def setup
      # No setup required
    end

    def configure_webhooks
      Pay::Webhooks.configure do |events|
        events.subscribe "purchasekit.subscription.created", PurchaseKit::Pay::Webhooks::SubscriptionCreated.new
        events.subscribe "purchasekit.subscription.updated", PurchaseKit::Pay::Webhooks::SubscriptionUpdated.new
        events.subscribe "purchasekit.subscription.canceled", PurchaseKit::Pay::Webhooks::SubscriptionCanceled.new
        events.subscribe "purchasekit.subscription.expired", PurchaseKit::Pay::Webhooks::SubscriptionExpired.new
      end
    end
  end
end
