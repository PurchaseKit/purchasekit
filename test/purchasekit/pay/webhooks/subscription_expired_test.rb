require "test_helper"

class PurchaseKit::Pay::Webhooks::SubscriptionExpiredTest < ActiveSupport::TestCase
  fixtures "pay/customers", "pay/subscriptions"

  def setup
    @handler = PurchaseKit::Pay::Webhooks::SubscriptionExpired.new
    @customer = pay_customers(:test_customer)
    @subscription = pay_subscriptions(:existing_subscription)
  end

  def test_sets_subscription_status_to_expired
    event = {
      "subscription_id" => @subscription.processor_id,
      "status" => "expired"
    }

    @handler.call(event)

    @subscription.reload
    assert_equal "expired", @subscription.status
  end

  def test_handles_missing_subscription_gracefully
    event = {
      "subscription_id" => "sub_nonexistent",
      "status" => "expired"
    }

    assert_nothing_raised { @handler.call(event) }
  end
end
