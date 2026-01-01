module PurchaseKit
  class WebhooksController < ApplicationController
    skip_forgery_protection

    def create
      event = verified_event
      event_type = event[:type].to_s.tr(".", "_").to_sym

      # Publish to event system (fires registered callbacks)
      PurchaseKit::Events.publish(event_type, event)

      # Queue for Pay's webhook processing if Pay is available
      PurchaseKit.queue_pay_webhook(event) if PurchaseKit.pay_enabled?

      head :ok
    rescue PurchaseKit::SignatureVerificationError => e
      Rails.logger.error "[PurchaseKit] Webhook signature error: #{e.message}"
      head :bad_request
    end

    private

    def verified_event
      payload = request.raw_post
      signature = request.headers["X-PurchaseKit-Signature"]
      secret = PurchaseKit.config.webhook_secret

      if secret.blank?
        if Rails.env.production?
          raise PurchaseKit::SignatureVerificationError, "webhook_secret must be configured"
        end
        return JSON.parse(payload, symbolize_names: true)
      end

      PurchaseKit::WebhookSignature.verified_payload(
        payload: payload,
        signature: signature,
        secret: secret
      )
    end
  end
end
