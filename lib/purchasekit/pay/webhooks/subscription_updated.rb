module PurchaseKit
  module Pay
    module Webhooks
      class SubscriptionUpdated < Base
        def call(event)
          update_subscription(event,
            processor_plan: event["store_product_id"],
            status: event["status"],
            current_period_start: parse_time(event["current_period_start"]),
            current_period_end: parse_time(event["current_period_end"]),
            ends_at: parse_time(event["ends_at"])
          )
        end
      end
    end
  end
end
