module PurchaseKit
  module Pay
    class PurchasesController < ApplicationController
      def create
        @customer = ::Pay::Customer.find(params[:customer_id])

        @intent = PurchaseKit::Purchase::Intent.create(
          product_id: params[:product_id],
          customer_id: @customer.id,
          success_path: params[:success_path],
          environment: params[:environment]
        )

        respond_to do |format|
          format.turbo_stream
        end
      end
    end
  end
end
