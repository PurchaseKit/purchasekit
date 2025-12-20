module PurchaseKit
  module Pay
    class Error < ::Pay::Error
    end

    class NotFoundError < Error
    end
  end
end
