module PurchaseKit
  module Purchase
    class DemoIntent < Intent
      attr_reader :customer_id, :success_path

      def initialize(id:, uuid:, product:, customer_id:, success_path:)
        super(id: id, uuid: uuid, product: product)
        @customer_id = customer_id
        @success_path = success_path
      end

      class << self
        def create(product_id:, customer_id:, success_path:)
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

        def find(uuid)
          intent = store[uuid]
          raise PurchaseKit::Pay::NotFoundError, "Intent not found: #{uuid}" unless intent
          intent
        end

        def store
          @store ||= {}
        end
      end
    end
  end
end
