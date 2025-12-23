require "test_helper"

class Pay::Purchasekit::ChargeTest < Minitest::Test
  def test_refund_raises_error
    charge = Pay::Purchasekit::Charge.new

    error = assert_raises(Pay::Purchasekit::Error) do
      charge.refund!
    end

    assert_equal "Refunds must be processed through App Store Connect or Google Play Console.", error.message
  end

  def test_refund_with_amount_raises_error
    charge = Pay::Purchasekit::Charge.new

    error = assert_raises(Pay::Purchasekit::Error) do
      charge.refund!(500)
    end

    assert_equal "Refunds must be processed through App Store Connect or Google Play Console.", error.message
  end
end
