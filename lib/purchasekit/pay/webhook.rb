module PurchaseKit
  module Pay
    class Webhook
      def self.queue(event)
        new(event).queue
      end

      def initialize(event)
        @event = event
      end

      def queue
        return unless listening?

        record = ::Pay::Webhook.create!(processor: :purchasekit, event_type:, event: @event)
        ProcessWebhookJob.perform_later(record.id)
      end

      private

      def event_type
        @event[:type]
      end

      def listening?
        ::Pay::Webhooks.delegator.listening?("purchasekit.#{event_type}")
      end

      class ProcessWebhookJob < ::ActiveJob::Base
        def perform(webhook_id)
          ::Pay::Webhook.find(webhook_id).process!
        end
      end
    end
  end
end
