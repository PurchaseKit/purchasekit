module PurchaseKit
  class Product
    # Demo implementation of Product for local development.
    #
    # Reads product data from PurchaseKit.config.demo_products instead
    # of making API calls. Designed for use with Xcode's StoreKit testing.
    #
    class Demo
      class << self
        def find(id)
          product_data = PurchaseKit.config.demo_products[id]
          raise PurchaseKit::NotFoundError, "Product not found: #{id}" unless product_data

          Product.new(
            id: id,
            apple_product_id: product_data[:apple_product_id],
            google_product_id: product_data[:google_product_id]
          )
        end
      end
    end
  end
end
