require "test_helper"

class PurchaseKit::Pay::Webhooks::SubscriptionCanceledTest < ActiveSupport::TestCase
  fixtures "pay/customers", "pay/subscriptions"

  def setup
    @handler = PurchaseKit::Pay::Webhooks::SubscriptionCanceled.new
    @customer = pay_customers(:test_customer)
    @subscription = pay_subscriptions(:existing_subscription)
  end

  def test_sets_subscription_status_to_canceled
    ends_at = 1.month.from_now
    event = {
      "subscription_id" => @subscription.processor_id,
      "status" => "canceled",
      "ends_at" => ends_at.iso8601
    }

    @handler.call(event)

    @subscription.reload
    assert_equal "canceled", @subscription.status
    assert_in_delta ends_at, @subscription.ends_at, 1.second
  end

  def test_handles_missing_subscription_gracefully
    event = {
      "subscription_id" => "sub_nonexistent",
      "status" => "canceled",
      "ends_at" => 1.month.from_now.iso8601
    }

    assert_nothing_raised { @handler.call(event) }
  end
end
