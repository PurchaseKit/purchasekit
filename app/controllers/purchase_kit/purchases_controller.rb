module PurchaseKit
  class PurchasesController < ApplicationController
    def create
      intent = PurchaseKit::Purchase::Intent.create(
        product_id: params[:product_id],
        customer_id: params[:customer_id],
        success_path: params[:success_path],
        environment: params[:environment]
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "purchasekit_paywall",
            partial: "purchase_kit/purchases/intent",
            locals: {intent: intent}
          )
        end
        format.json { render json: intent_json(intent) }
      end
    end

    private

    def intent_json(intent)
      {
        id: intent.id,
        uuid: intent.uuid,
        product: {
          id: intent.product.id,
          apple_product_id: intent.product.apple_product_id,
          google_product_id: intent.product.google_product_id
        }
      }
    end
  end
end
