module PurchaseKit
  class Product
    # Production implementation of Product that fetches from PurchaseKit API.
    #
    class Remote
      class << self
        def find(id)
          response = ApiClient.new.get("/products/#{id}")

          case response.code
          when 200
            Product.new(
              id: response["id"],
              apple_product_id: response["apple_product_id"],
              google_product_id: response["google_product_id"]
            )
          when 404
            raise PurchaseKit::NotFoundError, "Product not found: #{id}"
          else
            raise PurchaseKit::Error, "API error: #{response.code} #{response.message}"
          end
        end
      end
    end
  end
end
