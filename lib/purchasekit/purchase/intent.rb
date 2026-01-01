module PurchaseKit
  module Purchase
    # Represents a purchase intent - the record created before a user
    # initiates an in-app purchase.
    #
    # The intent contains a UUID that gets passed to the store as the
    # appAccountToken (Apple) or obfuscatedAccountId (Google). This allows
    # PurchaseKit to correlate the store's webhook with your user.
    #
    # Example:
    #   intent = PurchaseKit::Purchase::Intent.create(
    #     product_id: "prod_XXXXX",
    #     customer_id: current_user.payment_processor.id,
    #     success_path: "/dashboard",
    #     environment: "sandbox"
    #   )
    #
    #   intent.uuid     # => Pass to native app for store purchase
    #   intent.product  # => Contains store product IDs
    #
    class Intent
      attr_reader :id, :uuid, :product, :success_path

      def initialize(id:, uuid:, product:, success_path: nil)
        @id = id
        @uuid = uuid
        @product = product
        @success_path = success_path
      end

      # Override in subclasses if needed
      def xcode_completion_url
        nil
      end

      # Create a new purchase intent.
      #
      # @param product_id [String] The PurchaseKit product ID
      # @param customer_id [Integer, String] Your customer/user ID (will be included in webhooks)
      # @param success_path [String] Where to redirect after successful purchase
      # @param environment [String] "sandbox" or "production"
      # @return [Intent]
      # @raise [NotFoundError] if product doesn't exist
      # @raise [SubscriptionRequiredError] if PurchaseKit subscription needed for production
      #
      def self.create(product_id:, customer_id:, success_path: nil, environment: nil)
        if PurchaseKit.config.demo_mode?
          Demo.create(product_id:, customer_id:, success_path:)
        else
          Remote.create(product_id:, customer_id:, success_path:, environment:)
        end
      end
    end
  end
end
