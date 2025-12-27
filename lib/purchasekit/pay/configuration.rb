module PurchaseKit
  module Pay
    class Configuration
      attr_accessor :api_key, :api_url, :app_id, :webhook_secret
      attr_accessor :demo_mode, :demo_products

      def initialize
        @api_url = "https://purchasekit.dev"
        @demo_mode = false
        @demo_products = {}
      end

      def demo_mode?
        @demo_mode
      end

      def base_api_url
        "#{api_url}/api/v1"
      end

      def xcode_completion_url(intent_uuid:)
        if demo_mode?
          PurchaseKit::Pay::Engine.routes.url_helpers.purchase_intent_completions_url(intent_uuid: intent_uuid)
        else
          "#{base_api_url}/purchase/intents/#{intent_uuid}/completions"
        end
      end
    end

    class << self
      attr_writer :config

      def config
        @config ||= Configuration.new
      end

      def configure
        yield(config)
      end
    end
  end
end
