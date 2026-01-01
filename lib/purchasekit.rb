# PurchaseKit - In-app purchase webhooks for Rails
#
# This gem handles:
# - Configuration and API client
# - Product and purchase intent management
# - Webhook signature verification
# - Event callbacks for subscription lifecycle
# - Rails engine with webhooks controller and paywall helpers
# - Pay gem integration (auto-detected when Pay is present)

require "active_support"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/notifications"
require "active_support/security_utils"

require "purchasekit/version"
require "purchasekit/configuration"
require "purchasekit/error"
require "purchasekit/events"
require "purchasekit/webhook_signature"
require "purchasekit/api_client"
require "purchasekit/product"
require "purchasekit/product/demo"
require "purchasekit/product/remote"
require "purchasekit/purchase/intent"
require "purchasekit/purchase/intent/demo"
require "purchasekit/purchase/intent/remote"
require "purchasekit/engine"

module PurchaseKit
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
      defined?(::Pay)
    end

    def queue_pay_webhook(event)
      PurchaseKit::Pay::Webhook.queue(event)
    end
  end
end

# Load Pay integration if Pay gem is available
if PurchaseKit.pay_enabled?
  require "purchasekit/pay/webhooks"
  require "purchasekit/pay/webhook"
  require "pay/purchasekit"
end
