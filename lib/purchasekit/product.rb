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
        response = ApiClient.new.get("/products/#{id}")

        case response.code
        when 200
          new(
            id: response["id"],
            apple_product_id: response["apple_product_id"],
            google_product_id: response["google_product_id"]
          )
        when 404
          raise Pay::NotFoundError, "Product not found: #{id}"
        else
          raise Pay::Error, "API error: #{response.code} #{response.message}"
        end
      end
    end
  end
end
