module PurchaseKit
  module Purchase
    class Intent
      attr_reader :id, :uuid, :product

      def initialize(id:, uuid:, product:)
        @id = id
        @uuid = uuid
        @product = product
      end

      class << self
        def create(product_id:, customer_id:, success_path: nil, environment: nil)
          if PurchaseKit::Pay.config.demo_mode?
            DemoIntent.create(product_id: product_id, customer_id: customer_id, success_path: success_path)
          else
            create_remote(product_id: product_id, customer_id: customer_id, success_path: success_path, environment: environment)
          end
        end

        private

        def create_remote(product_id:, customer_id:, success_path:, environment:)
          response = ApiClient.new.post("/purchase/intents", {
            product_id: product_id,
            customer_id: customer_id,
            success_path: success_path,
            environment: environment
          })

          case response.code
          when 201
            product_data = response["product"]
            product = Product.new(
              id: product_data["id"],
              apple_product_id: product_data["apple_product_id"],
              google_product_id: product_data["google_product_id"]
            )
            new(id: response["id"], uuid: response["uuid"], product: product)
          when 402
            raise PurchaseKit::Pay::SubscriptionRequiredError, response["error"] || "Subscription required for production purchases"
          when 404
            raise PurchaseKit::Pay::NotFoundError, "App or product not found"
          else
            raise PurchaseKit::Pay::Error, "API error: #{response.code} #{response.message}"
          end
        end
      end
    end
  end
end
