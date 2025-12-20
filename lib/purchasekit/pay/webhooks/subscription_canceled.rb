module PurchaseKit
  module Pay
    module Webhooks
      class SubscriptionCanceled < Base
        def call(event)
          update_subscription(event, status: :canceled, ends_at: parse_time(event["ends_at"]))
        end
      end
    end
  end
end
