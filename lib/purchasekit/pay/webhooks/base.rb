module PurchaseKit
  module Pay
    module Webhooks
      class Base
        private

        def update_subscription(event, attributes)
          pay_subscription = find_subscription(event)
          return unless pay_subscription

          pay_subscription.update!(attributes)
        end

        def find_subscription(event)
          ::Pay::Subscription.find_by(processor_id: event["subscription_id"])
        end

        def parse_time(value)
          return nil if value.blank?
          Time.zone.parse(value)
        end
      end
    end
  end
end
