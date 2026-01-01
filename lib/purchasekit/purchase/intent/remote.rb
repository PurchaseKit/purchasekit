module PurchaseKit
  module Purchase
    class Intent
      # Production implementation of Intent that creates via PurchaseKit API.
      #
      class Remote < Intent
        class << self
          def create(product_id:, customer_id:, success_path: nil, environment: nil)
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
              new(id: response["id"], uuid: response["uuid"], product: product, success_path: success_path)
            when 402
              raise PurchaseKit::SubscriptionRequiredError, response["error"] || "Subscription required for production purchases"
            when 404
              raise PurchaseKit::NotFoundError, "App or product not found"
            else
              raise PurchaseKit::Error, "API error: #{response.code} #{response.message}"
            end
          end
        end
      end
    end
  end
end
