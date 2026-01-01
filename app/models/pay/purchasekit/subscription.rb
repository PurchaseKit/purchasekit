module Pay
  module Purchasekit
    class Subscription < Pay::Subscription
      def cancel(**options)
        raise Pay::Purchasekit::Error, "Cancel through App Store or Google Play."
      end

      def cancel_now!(**options)
        raise Pay::Purchasekit::Error, "Cancel through App Store or Google Play."
      end

      def resume
        raise Pay::Purchasekit::Error, "Resume through App Store or Google Play."
      end

      def swap(plan, **options)
        raise Pay::Purchasekit::Error, "Change plans through App Store or Google Play."
      end

      def change_quantity(quantity, **options)
        raise Pay::Purchasekit::Error, "Quantity changes not supported for in-app purchases."
      end

      def paused?
        false
      end

      def pause(**options)
        raise Pay::Purchasekit::Error, "Pause through App Store or Google Play."
      end
    end
  end
end
