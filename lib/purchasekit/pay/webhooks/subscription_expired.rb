module PurchaseKit
  module Pay
    module Webhooks
      class SubscriptionExpired < Base
        def call(event)
          update_subscription(event, status: :expired)
        end
      end
    end
  end
end
