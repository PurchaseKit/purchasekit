module PurchaseKit
  module Purchase
    # Demo mode only - simulates purchase completion for Xcode StoreKit testing
    class CompletionsController < ApplicationController
      skip_forgery_protection

      def create
        return head :not_found unless PurchaseKit.config.demo_mode?

        intent = Intent::Demo.find(params[:id])

        # Simulate a subscription.created webhook
        event = {
          type: "subscription.created",
          customer_id: intent.customer_id.to_s,
          subscription_id: "sub_#{SecureRandom.hex(12)}",
          store: "apple",
          store_product_id: intent.product.apple_product_id,
          subscription_name: "Demo Subscription",
          status: "active",
          current_period_start: Time.current.iso8601,
          current_period_end: 1.year.from_now.iso8601,
          ends_at: nil,
          success_path: intent.success_path
        }

        # Publish the event (triggers callbacks and Pay integration if available)
        PurchaseKit::Events.publish(:subscription_created, event)

        # Queue for Pay if available
        PurchaseKit::Pay::Webhook.queue(event) if PurchaseKit.pay_enabled?

        redirect_to intent.success_path || main_app.root_path, notice: "Purchase completed!"
      rescue PurchaseKit::NotFoundError
        head :not_found
      end
    end
  end
end
