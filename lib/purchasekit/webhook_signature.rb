require "openssl"
require "json"

module PurchaseKit
  # Verifies HMAC-SHA256 signatures on incoming webhooks.
  #
  # The PurchaseKit SaaS signs all webhook payloads with your webhook secret.
  # This class verifies those signatures to ensure webhooks are authentic.
  #
  # Example:
  #   PurchaseKit::WebhookSignature.verify!(
  #     payload: request.raw_post,
  #     signature: request.headers["X-PurchaseKit-Signature"],
  #     secret: PurchaseKit.config.webhook_secret
  #   )
  #
  class WebhookSignature
    attr_reader :payload, :signature, :secret

    def initialize(payload:, signature:, secret:)
      @payload = payload
      @signature = signature
      @secret = secret
    end

    # Verify the signature. Raises SignatureVerificationError if invalid.
    def verify!
      if secret.blank?
        raise SignatureVerificationError, "webhook_secret must be configured"
      end

      if signature.blank?
        raise SignatureVerificationError, "Missing signature"
      end

      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
      unless ActiveSupport::SecurityUtils.secure_compare(signature, expected)
        raise SignatureVerificationError, "Invalid signature"
      end

      true
    end

    # Verify the signature and return the parsed JSON payload.
    def verified_payload
      verify!
      JSON.parse(payload, symbolize_names: true)
    end

    class << self
      def verify!(payload:, signature:, secret:)
        new(payload: payload, signature: signature, secret: secret).verify!
      end

      def verified_payload(payload:, signature:, secret:)
        new(payload: payload, signature: signature, secret: secret).verified_payload
      end
    end
  end
end
