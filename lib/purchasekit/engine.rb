module PurchaseKit
  class Engine < ::Rails::Engine
    isolate_namespace PurchaseKit

    initializer "purchasekit.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper PurchaseKit::PaywallHelper
      end
    end

    initializer "purchasekit.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << Engine.root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << Engine.root.join("app/javascript")
      end
    end

    initializer "purchasekit.assets" do |app|
      if app.config.respond_to?(:assets) && app.config.assets.respond_to?(:paths)
        app.config.assets.paths << Engine.root.join("app/javascript")
        app.config.assets.precompile += %w[purchasekit/manifest.js]
      end
    end

    # Pay gem integration (only when Pay is available)
    initializer "purchasekit.pay_processor", before: :load_config_initializers do
      if PurchaseKit.pay_enabled?
        ::Pay.enabled_processors << :purchasekit unless ::Pay.enabled_processors.include?(:purchasekit)
      end
    end

    initializer "purchasekit.pay_webhooks", after: :load_config_initializers do
      if PurchaseKit.pay_enabled?
        ::Pay::Purchasekit.configure_webhooks
      end
    end
  end
end
