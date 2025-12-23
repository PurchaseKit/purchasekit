require "test_helper"

class Pay::Purchasekit::CustomerTest < Minitest::Test
  def test_model_name_returns_pay_customer
    assert_equal Pay::Customer.model_name, Pay::Purchasekit::Customer.model_name
  end

  def test_charge_raises_error
    customer = Pay::Purchasekit::Customer.new

    error = assert_raises(Pay::Purchasekit::Error) do
      customer.charge(1000)
    end

    assert_equal "One-time charges not supported. Use in-app purchases.", error.message
  end

  def test_subscribe_raises_error
    customer = Pay::Purchasekit::Customer.new

    error = assert_raises(Pay::Purchasekit::Error) do
      customer.subscribe
    end

    assert_equal "Subscriptions must be initiated through the native app.", error.message
  end

  def test_add_payment_method_raises_error
    customer = Pay::Purchasekit::Customer.new

    error = assert_raises(Pay::Purchasekit::Error) do
      customer.add_payment_method("pm_test")
    end

    assert_equal "Payment methods managed by App Store or Google Play.", error.message
  end
end
