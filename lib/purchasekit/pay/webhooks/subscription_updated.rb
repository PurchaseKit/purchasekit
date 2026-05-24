module PurchaseKit
  module Pay
    module Webhooks
      class SubscriptionUpdated < Base
        include ActionView::RecordIdentifier
        include Turbo::Streams::ActionHelper

        def call(event)
          customer = ::Pay::Customer.find(event["customer_id"])

          subscription = ::Pay::Purchasekit::Subscription.find_or_initialize_by(
            customer: customer,
            processor_id: event["subscription_id"]
          )
          subscription.name ||= event["subscription_name"] || ::Pay.default_product_name
          subscription.quantity ||= 1

          subscription.update!(
            processor_plan: event["store_product_id"],
            status: event["status"],
            current_period_start: parse_time(event["current_period_start"]),
            current_period_end: parse_time(event["current_period_end"]),
            trial_ends_at: parse_time(event["trial_ends_at"]),
            ends_at: parse_time(event["ends_at"]),
            data: (subscription.data || {}).merge("store" => event["store"])
          )

          broadcast_redirect(customer, event) if event["success_path"].present?
        end

        private

        def broadcast_redirect(customer, event)
          Turbo::StreamsChannel.broadcast_stream_to(
            dom_id(customer),
            content: turbo_stream_action_tag(:redirect, url: event["success_path"])
          )
        end
      end
    end
  end
end
