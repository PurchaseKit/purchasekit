module PurchaseKit
  module Pay
    class Configuration
      attr_accessor :api_key, :api_url, :app_id, :webhook_secret

      def initialize
        @api_url = "https://purchasekit.dev"
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
