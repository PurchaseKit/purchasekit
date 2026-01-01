module PurchaseKit
  # Base error class for all PurchaseKit errors
  class Error < StandardError
  end

  # Raised when a resource is not found (404)
  class NotFoundError < Error
  end

  # Raised when a PurchaseKit subscription is required (402)
  # This happens when trying to create purchase intents in production
  # without an active PurchaseKit subscription
  class SubscriptionRequiredError < Error
  end

  # Raised when webhook signature verification fails
  class SignatureVerificationError < Error
  end
end
