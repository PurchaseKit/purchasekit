module PurchaseKit
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    rescue_from PurchaseKit::NotFoundError, with: :handle_not_found
    rescue_from PurchaseKit::SubscriptionRequiredError, with: :handle_subscription_required

    private

    def handle_not_found(exception)
      handle_error("Product not found", :not_found)
    end

    def handle_subscription_required(exception)
      handle_error("PurchaseKit subscription required", :payment_required)
    end

    def handle_error(message, status)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "purchasekit_paywall",
            partial: "purchase_kit/purchases/error",
            locals: {message: message}
          )
        end
        format.json { render json: {error: message}, status: status }
      end
    end
  end
end
