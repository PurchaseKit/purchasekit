module PurchaseKit
  module Pay
    module Webhooks
      class SubscriptionCreated < Base
        include ActionView::RecordIdentifier
        include Turbo::Streams::ActionHelper

        def call(event)
          customer = ::Pay::Customer.find(event["customer_id"])

          subscription = ::Pay::Purchasekit::Subscription.find_or_initialize_by(
            customer: customer,
            processor_id: event["subscription_id"]
          )
          is_new = subscription.new_record?

          subscription.update!(
            name: event["subscription_name"] || ::Pay.default_product_name,
            processor_plan: event["store_product_id"],
            status: :active,
            quantity: 1,
            current_period_start: parse_time(event["current_period_start"]),
            current_period_end: parse_time(event["current_period_end"]),
            ends_at: parse_time(event["ends_at"]),
            data: (subscription.data || {}).merge("store" => event["store"])
          )

          return unless is_new

          redirect_path = event["success_path"] || Rails.application.routes.url_helpers.root_path
          Turbo::StreamsChannel.broadcast_stream_to(
            dom_id(customer),
            content: turbo_stream_action_tag(:redirect, url: redirect_path)
          )
        end
      end
    end
  end
end
