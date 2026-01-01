require "securerandom"

module PurchaseKit
  module Purchase
    class Intent
      # Demo implementation of Intent for local development.
      #
      # Stores intents in memory instead of making API calls.
      # Designed for use with Xcode's StoreKit testing.
      #
      class Demo < Intent
        attr_reader :customer_id

        def initialize(id:, uuid:, product:, customer_id:, success_path:)
          super(id: id, uuid: uuid, product: product, success_path: success_path)
          @customer_id = customer_id
        end

        # URL for Xcode StoreKit testing to simulate purchase completion
        def xcode_completion_url
          "/purchasekit/purchase/completions/#{uuid}"
        end

        class << self
          def find(uuid)
            intent = store[uuid]
            raise PurchaseKit::NotFoundError, "Intent not found: #{uuid}" unless intent
            intent
          end

          def create(product_id:, customer_id:, success_path: nil, environment: nil)
            product = Product.find(product_id)
            uuid = SecureRandom.uuid
            id = "intent_#{SecureRandom.hex(8)}"

            intent = new(
              id: id,
              uuid: uuid,
              product: product,
              customer_id: customer_id,
              success_path: success_path
            )
            store[uuid] = intent
            intent
          end

          def store
            @store ||= {}
          end

          # Clear the in-memory store (useful for tests)
          def clear_store!
            @store = {}
          end
        end
      end
    end
  end
end
