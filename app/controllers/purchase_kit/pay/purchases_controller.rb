class PurchaseKit::Pay::PurchasesController < PurchaseKit::Pay::ApplicationController
  rescue_from PurchaseKit::Pay::SubscriptionRequiredError, with: :subscription_required

  def create
    @customer = ::Pay::Customer.find(params[:customer_id])

    @intent = PurchaseKit::Purchase::Intent.create(
      product_id: params[:product_id],
      customer_id: @customer.id,
      success_path: params[:success_path],
      environment: params[:environment]
    )

    @xcode_completion_url = PurchaseKit::Pay.config.xcode_completion_url(intent_uuid: @intent.uuid, host: request.base_url)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def subscription_required(exception)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "purchasekit_paywall",
          partial: "purchase_kit/pay/purchases/subscription_required",
          locals: {message: exception.message}
        )
      end
    end
  end
end
