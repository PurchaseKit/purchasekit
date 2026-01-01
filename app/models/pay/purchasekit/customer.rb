module Pay
  module Purchasekit
    class Customer < Pay::Customer
      # Use base class name for dom_id to keep stream names consistent
      def self.model_name
        Pay::Customer.model_name
      end

      def charge(amount, options = {})
        raise Pay::Purchasekit::Error, "One-time charges not supported. Use in-app purchases."
      end

      def subscribe(name: Pay.default_product_name, plan: Pay.default_plan_name, **options)
        raise Pay::Purchasekit::Error, "Subscriptions must be initiated through the native app."
      end

      def add_payment_method(payment_method_id, default: false)
        raise Pay::Purchasekit::Error, "Payment methods managed by App Store or Google Play."
      end
    end
  end
end
