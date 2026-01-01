module PurchaseKit
  # Represents a product configured in the PurchaseKit dashboard.
  #
  # Products contain the store-specific product IDs for Apple and Google.
  # Display text (name, description, price) should be fetched from the
  # stores at runtime or defined in your views for i18n support.
  #
  # Example:
  #   product = PurchaseKit::Product.find("prod_XXXXX")
  #   product.apple_product_id  # => "com.example.pro.annual"
  #   product.google_product_id # => "pro_annual"
  #
  class Product
    attr_reader :id, :apple_product_id, :google_product_id

    def initialize(id:, apple_product_id: nil, google_product_id: nil)
      @id = id
      @apple_product_id = apple_product_id
      @google_product_id = google_product_id
    end

    # Get the store-specific product ID for a platform.
    #
    # @param platform [Symbol] :apple or :google
    # @return [String] The store product ID
    #
    def store_product_id(platform:)
      case platform
      when :apple then apple_product_id
      when :google then google_product_id
      else raise ArgumentError, "Unknown platform: #{platform}"
      end
    end

    # Find a product by ID.
    #
    # In demo mode, reads from configured demo_products.
    # In production, fetches from the PurchaseKit API.
    #
    # @param id [String] The product ID (e.g., "prod_XXXXX" or a demo key)
    # @return [Product]
    # @raise [NotFoundError] if product doesn't exist
    #
    def self.find(id)
      if PurchaseKit.config.demo_mode?
        Demo.find(id)
      else
        Remote.find(id)
      end
    end
  end
end
