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
          response = ApiClient.new.post("/purchase_intents", {
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
          when 404
            raise Pay::NotFoundError, "App or product not found"
          else
            raise Pay::Error, "API error: #{response.code} #{response.message}"
          end
        end
      end
    end
  end
end
