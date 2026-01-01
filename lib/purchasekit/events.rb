module PurchaseKit
  module Events
    TYPES = %i[
      subscription_created
      subscription_updated
      subscription_canceled
      subscription_expired
    ].freeze

    class << self
      # Publish an event to all registered handlers.
      #
      # Also publishes via ActiveSupport::Notifications for additional flexibility.
      #
      # @param type [Symbol] Event type (e.g., :subscription_created)
      # @param payload [Hash] Event payload from the webhook
      # @return [Event] The published event
      #
      def publish(type, payload)
        event = Event.new(type: type, payload: payload)

        # Call registered block handlers
        PurchaseKit.config.handlers_for(type).each do |handler|
          handler.call(event)
        end

        # Also publish via ActiveSupport::Notifications for subscribers
        ActiveSupport::Notifications.instrument("purchasekit.#{type}", event: event)

        event
      end
    end

    # Represents a subscription event from Apple or Google.
    #
    # Events are normalized by the PurchaseKit SaaS before being sent
    # to your application, so you get a consistent interface regardless
    # of which store the purchase came from.
    #
    class Event
      attr_reader :type, :payload

      def initialize(type:, payload:)
        @type = type.to_sym
        @payload = payload.is_a?(Hash) ? payload.with_indifferent_access : payload
      end

      # The customer ID you passed when creating the purchase intent.
      # Use this to look up the user in your database.
      def customer_id
        payload[:customer_id]
      end

      # The unique subscription ID from the store.
      # Apple: originalTransactionId
      # Google: purchaseToken
      def subscription_id
        payload[:subscription_id]
      end

      # Which store the purchase came from: "apple" or "google"
      def store
        payload[:store]
      end

      # The store-specific product ID (e.g., "com.example.pro.annual")
      def store_product_id
        payload[:store_product_id]
      end

      # The subscription name you configured in PurchaseKit
      def subscription_name
        payload[:subscription_name]
      end

      # Current status: "active", "canceled", "expired", etc.
      def status
        payload[:status]
      end

      # When the current billing period started
      def current_period_start
        parse_time(payload[:current_period_start])
      end

      # When the current billing period ends
      def current_period_end
        parse_time(payload[:current_period_end])
      end

      # When the subscription will end (for canceled subscriptions)
      def ends_at
        parse_time(payload[:ends_at])
      end

      # The success path you passed when creating the purchase intent.
      # Use this for redirecting after purchase completion.
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
end
