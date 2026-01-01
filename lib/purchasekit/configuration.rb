module PurchaseKit
  class Configuration
    attr_accessor :api_key, :api_url, :app_id, :webhook_secret
    attr_accessor :demo_mode, :demo_products

    def initialize
      @api_url = "https://purchasekit.dev"
      @demo_mode = false
      @demo_products = {}
      @event_handlers = Hash.new { |h, k| h[k] = [] }
    end

    def demo_mode?
      @demo_mode
    end

    def base_api_url
      "#{api_url}/api/v1"
    end

    # Register a callback for an event type.
    #
    # Available events:
    # - :subscription_created
    # - :subscription_updated
    # - :subscription_canceled
    # - :subscription_expired
    #
    # Example:
    #   PurchaseKit.configure do |config|
    #     config.on(:subscription_created) do |event|
    #       user = User.find(event.customer_id)
    #       user.update!(subscribed: true)
    #     end
    #   end
    #
    def on(event_type, &block)
      @event_handlers[event_type.to_sym] << block
    end

    # Get handlers for an event type (internal use)
    def handlers_for(event_type)
      @event_handlers[event_type.to_sym]
    end

    # Check if any handlers are registered for an event type
    def listening?(event_type)
      @event_handlers[event_type.to_sym].any?
    end
  end
end
