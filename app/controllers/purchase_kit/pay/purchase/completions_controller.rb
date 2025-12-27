class PurchaseKit::Pay::Purchase::CompletionsController < PurchaseKit::Pay::ApplicationController
  include ActionView::RecordIdentifier
  include Turbo::Streams::ActionHelper

  skip_before_action :verify_authenticity_token

  def create
    unless PurchaseKit::Pay.config.demo_mode?
      head :not_found
      return
    end

    intent = PurchaseKit::Purchase::DemoIntent.find(params[:intent_uuid])
    customer = ::Pay::Customer.find(intent.customer_id)

    customer.subscriptions.create!(
      name: "default",
      processor_id: "demo_#{SecureRandom.hex(12)}",
      processor_plan: intent.product.apple_product_id,
      status: "active",
      quantity: 1
    )

    redirect_path = intent.success_path || "/"
    Turbo::StreamsChannel.broadcast_stream_to(
      dom_id(customer),
      content: turbo_stream_action_tag(:redirect, url: redirect_path)
    )

    head :ok
  end
end
