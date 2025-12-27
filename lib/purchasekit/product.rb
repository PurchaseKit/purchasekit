module PurchaseKit
  class Product
    attr_reader :id, :apple_product_id, :google_product_id

    def initialize(id:, apple_product_id: nil, google_product_id: nil)
      @id = id
      @apple_product_id = apple_product_id
      @google_product_id = google_product_id
    end

    def store_product_id(platform:)
      case platform
      when :apple then apple_product_id
      when :google then google_product_id
      else raise ArgumentError, "Unknown platform: #{platform}"
      end
    end

    class << self
      def find(id)
        if PurchaseKit::Pay.config.demo_mode?
          find_demo(id)
        else
          find_remote(id)
        end
      end

      private

      def find_demo(id)
        product_data = PurchaseKit::Pay.config.demo_products[id]
        raise PurchaseKit::Pay::NotFoundError, "Product not found: #{id}" unless product_data

        new(
          id: id,
          apple_product_id: product_data[:apple_product_id],
          google_product_id: product_data[:google_product_id]
        )
      end

      def find_remote(id)
        response = ApiClient.new.get("/products/#{id}")

        case response.code
        when 200
          new(
            id: response["id"],
            apple_product_id: response["apple_product_id"],
            google_product_id: response["google_product_id"]
          )
        when 404
          raise PurchaseKit::Pay::NotFoundError, "Product not found: #{id}"
        else
          raise PurchaseKit::Pay::Error, "API error: #{response.code} #{response.message}"
        end
      end
    end
  end
end
