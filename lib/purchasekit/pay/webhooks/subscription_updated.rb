module PurchaseKit
  module Pay
    module Webhooks
      class SubscriptionUpdated < Base
        include ActionView::RecordIdentifier
        include Turbo::Streams::ActionHelper

        def call(event)
          update_subscription(event,
            processor_plan: event["store_product_id"],
            status: event["status"],
            current_period_start: parse_time(event["current_period_start"]),
            current_period_end: parse_time(event["current_period_end"]),
            ends_at: parse_time(event["ends_at"]))

          broadcast_redirect(event) if event["success_path"].present?
        end

        private

        def broadcast_redirect(event)
          customer = ::Pay::Customer.find(event["customer_id"])
          Turbo::StreamsChannel.broadcast_stream_to(
            dom_id(customer),
            content: turbo_stream_action_tag(:redirect, url: event["success_path"])
          )
        end
      end
    end
  end
end
