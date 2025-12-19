require "httparty"

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
          config = PurchaseKit::Pay.config

          response = HTTParty.post(
            "#{config.api_url}/api/v1/apps/#{config.app_id}/purchase_intents",
            headers: {
              "Authorization" => "Bearer #{config.api_key}",
              "Accept" => "application/json",
              "Content-Type" => "application/json"
            },
            body: {
              product_id: product_id,
              customer_id: customer_id,
              success_path: success_path,
              environment: environment
            }.to_json
          )

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
            raise NotFoundError, "App or product not found"
          else
            raise Error, "API error: #{response.code} #{response.message}"
          end
        end
      end

      class NotFoundError < StandardError; end
      class Error < StandardError; end
    end
  end
end
