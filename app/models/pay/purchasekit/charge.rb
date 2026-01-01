module Pay
  module Purchasekit
    class Charge < Pay::Charge
      def refund!(amount = nil)
        raise Pay::Purchasekit::Error, "Refunds must be processed through App Store Connect or Google Play Console."
      end
    end
  end
end
