require "httparty"

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
        config = PurchaseKit::Pay.config

        response = HTTParty.get(
          "#{config.api_url}/api/v1/apps/#{config.app_id}/products/#{id}",
          headers: {
            "Authorization" => "Bearer #{config.api_key}",
            "Accept" => "application/json"
          }
        )

        case response.code
        when 200
          new(
            id: response["id"],
            apple_product_id: response["apple_product_id"],
            google_product_id: response["google_product_id"]
          )
        when 404
          raise NotFoundError, "Product not found: #{id}"
        else
          raise Error, "API error: #{response.code} #{response.message}"
        end
      end
    end

    class NotFoundError < StandardError; end
    class Error < StandardError; end
  end
end
