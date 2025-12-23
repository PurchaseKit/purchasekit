class PurchaseKit::Pay::WebhooksController < PurchaseKit::Pay::ApplicationController
  skip_forgery_protection

  def create
    PurchaseKit::Pay::Webhook.queue(verified_event)
    head :ok
  rescue SignatureVerificationError => e
    Rails.logger.error "[PurchaseKit] Webhook signature error: #{e.message}"
    head :bad_request
  end

  private

  def verified_event
    payload = request.raw_post
    signature = request.headers["X-PurchaseKit-Signature"]
    secret = PurchaseKit::Pay.config.webhook_secret

    return JSON.parse(payload, symbolize_names: true) if secret.blank?

    raise SignatureVerificationError, "Missing signature" if signature.blank?

    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
    unless ActiveSupport::SecurityUtils.secure_compare(signature, expected)
      raise SignatureVerificationError, "Invalid signature"
    end

    JSON.parse(payload, symbolize_names: true)
  end

  class SignatureVerificationError < StandardError; end
end
