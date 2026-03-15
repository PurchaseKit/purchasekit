# Standalone test helper - tests PurchaseKit without Pay gem
# Uses only ActiveSupport, not a full Rails app

require "minitest/autorun"
require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/time"

# Set up Time.zone for the tests
Time.zone = "UTC"

# Require just the core gem files (not the engine or events which need Rails)
require "purchasekit/version"
require "purchasekit/configuration"
require "purchasekit/error"

# Define a minimal Event class for testing (the full Events module requires ActionView)
module PurchaseKit
  module Events
    class Event
      attr_reader :type, :payload

      def initialize(type:, payload:)
        @type = type.to_sym
        @payload = payload.is_a?(Hash) ? payload.with_indifferent_access : payload
      end

      def event_id
        payload[:event_id]
      end

      def customer_id
        payload[:customer_id]
      end

      def subscription_id
        payload[:subscription_id]
      end

      def store
        payload[:store]
      end

      def store_product_id
        payload[:store_product_id]
      end

      def subscription_name
        payload[:subscription_name]
      end

      def status
        payload[:status]
      end

      def current_period_start
        parse_time(payload[:current_period_start])
      end

      def current_period_end
        parse_time(payload[:current_period_end])
      end

      def ends_at
        parse_time(payload[:ends_at])
      end

      def trial_ends_at
        parse_time(payload[:trial_ends_at])
      end

      def success_path
        payload[:success_path]
      end

      private

      def parse_time(value)
        return nil if value.blank?
        Time.zone.parse(value)
      rescue
        Time.parse(value) rescue nil
      end
    end
  end

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    def reset_config!
      @config = Configuration.new
    end

    def pay_enabled?
      defined?(::Pay) && defined?(::Pay::VERSION)
    end
  end
end

# Configure PurchaseKit with test values
PurchaseKit.configure do |config|
  config.api_url = "http://localhost:3000"
  config.api_key = "sk_test_key"
  config.app_id = "app_TEST123"
  config.webhook_secret = "whsec_test_secret"
end

module PurchaseKit
  class StandaloneTestCase < Minitest::Test
  end
end
