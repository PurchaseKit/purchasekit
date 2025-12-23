module PurchaseKit
  module Pay
    class Engine < ::Rails::Engine
      isolate_namespace PurchaseKit::Pay

      initializer "purchasekit_pay.register_processor", before: :load_config_initializers do
        ::Pay.enabled_processors << :purchasekit unless ::Pay.enabled_processors.include?(:purchasekit)
      end

      initializer "purchasekit_pay.webhooks", after: :load_config_initializers do
        ::Pay::Purchasekit.configure_webhooks
      end

      initializer "purchasekit_pay.helpers" do
        ActiveSupport.on_load(:action_controller_base) do
          helper PurchaseKit::Pay::PaywallHelper
        end
      end

      initializer "purchasekit_pay.importmap", before: "importmap" do |app|
        if app.config.respond_to?(:importmap)
          app.config.importmap.paths << Engine.root.join("config/importmap.rb")
          app.config.importmap.cache_sweepers << root.join("app/javascript")
        end
      end

      initializer "purchasekit_pay.assets" do |app|
        if app.config.respond_to?(:assets) && app.config.assets.respond_to?(:paths)
          app.config.assets.paths << root.join("app/javascript")
          app.config.assets.precompile += %w[purchasekit-pay/manifest.js]
        end
      end
    end
  end
end
