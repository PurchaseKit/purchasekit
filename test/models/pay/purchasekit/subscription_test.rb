require "test_helper"

class Pay::Purchasekit::SubscriptionTest < Minitest::Test
  def test_cancel_raises_error
    subscription = Pay::Purchasekit::Subscription.new

    error = assert_raises(Pay::Purchasekit::Error) do
      subscription.cancel
    end

    assert_equal "Cancel through App Store or Google Play.", error.message
  end

  def test_cancel_now_raises_error
    subscription = Pay::Purchasekit::Subscription.new

    error = assert_raises(Pay::Purchasekit::Error) do
      subscription.cancel_now!
    end

    assert_equal "Cancel through App Store or Google Play.", error.message
  end

  def test_resume_raises_error
    subscription = Pay::Purchasekit::Subscription.new

    error = assert_raises(Pay::Purchasekit::Error) do
      subscription.resume
    end

    assert_equal "Resume through App Store or Google Play.", error.message
  end

  def test_swap_raises_error
    subscription = Pay::Purchasekit::Subscription.new

    error = assert_raises(Pay::Purchasekit::Error) do
      subscription.swap("new_plan")
    end

    assert_equal "Change plans through App Store or Google Play.", error.message
  end

  def test_change_quantity_raises_error
    subscription = Pay::Purchasekit::Subscription.new

    error = assert_raises(Pay::Purchasekit::Error) do
      subscription.change_quantity(2)
    end

    assert_equal "Quantity changes not supported for in-app purchases.", error.message
  end

  def test_paused_returns_false
    subscription = Pay::Purchasekit::Subscription.new

    assert_equal false, subscription.paused?
  end

  def test_pause_raises_error
    subscription = Pay::Purchasekit::Subscription.new

    error = assert_raises(Pay::Purchasekit::Error) do
      subscription.pause
    end

    assert_equal "Pause through App Store or Google Play.", error.message
  end
end
