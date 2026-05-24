require "test_helper"

class PurchaseKit::Pay::Webhooks::SubscriptionUpdatedTest < ActiveSupport::TestCase
  fixtures "pay/customers", "pay/subscriptions"

  def setup
    @handler = PurchaseKit::Pay::Webhooks::SubscriptionUpdated.new
    @customer = pay_customers(:test_customer)
    @subscription = pay_subscriptions(:existing_subscription)
  end

  def test_updates_subscription_status_and_dates
    new_end_date = 2.months.from_now
    event = {
      "customer_id" => @customer.id,
      "subscription_id" => @subscription.processor_id,
      "store_product_id" => "com.example.monthly",
      "status" => "active",
      "current_period_start" => Time.current.iso8601,
      "current_period_end" => new_end_date.iso8601,
      "ends_at" => nil
    }

    @handler.call(event)

    @subscription.reload
    assert_equal "com.example.monthly", @subscription.processor_plan
    assert_equal "active", @subscription.status
    assert_in_delta new_end_date, @subscription.current_period_end, 1.second
  end

  def test_broadcasts_redirect_when_success_path_present
    event = {
      "customer_id" => @customer.id,
      "subscription_id" => @subscription.processor_id,
      "store_product_id" => "com.example.monthly",
      "status" => "active",
      "current_period_start" => Time.current.iso8601,
      "current_period_end" => 1.month.from_now.iso8601,
      "ends_at" => nil,
      "success_path" => "/dashboard"
    }

    broadcast_called = false
    Turbo::StreamsChannel.stub :broadcast_stream_to, ->(*args) { broadcast_called = true } do
      @handler.call(event)
    end

    assert broadcast_called, "Expected Turbo broadcast when success_path is present"
  end

  def test_does_not_broadcast_when_success_path_missing
    event = {
      "customer_id" => @customer.id,
      "subscription_id" => @subscription.processor_id,
      "store_product_id" => "com.example.monthly",
      "status" => "active",
      "current_period_start" => Time.current.iso8601,
      "current_period_end" => 1.month.from_now.iso8601,
      "ends_at" => nil
    }

    broadcast_called = false
    Turbo::StreamsChannel.stub :broadcast_stream_to, ->(*args) { broadcast_called = true } do
      @handler.call(event)
    end

    refute broadcast_called, "Expected no broadcast when success_path is missing"
  end

  def test_clears_trial_ends_at_after_trial
    event = {
      "customer_id" => @customer.id,
      "subscription_id" => @subscription.processor_id,
      "store_product_id" => "com.example.monthly",
      "status" => "active",
      "current_period_start" => Time.current.iso8601,
      "current_period_end" => 1.month.from_now.iso8601,
      "trial_ends_at" => nil,
      "ends_at" => nil
    }

    @handler.call(event)

    @subscription.reload
    assert_nil @subscription.trial_ends_at
  end

  # Apple's sandbox sends DID_RENEW (mapped to subscription.updated) on a fresh
  # purchase when the same Apple ID previously subscribed to the same product,
  # so the first webhook for a sandbox subscription can be `subscription.updated`
  # with no prior `subscription.created`. Same shape happens in production for
  # users who subscribed before PurchaseKit was integrated: their next renewal
  # arrives as `subscription.updated` with no row yet.
  def test_creates_subscription_when_row_missing
    event = {
      "customer_id" => @customer.id,
      "subscription_id" => "sub_renewed_first",
      "store" => "apple",
      "store_product_id" => "com.example.monthly",
      "subscription_name" => "pro",
      "status" => "active",
      "current_period_start" => Time.current.iso8601,
      "current_period_end" => 1.month.from_now.iso8601,
      "ends_at" => nil
    }

    @handler.call(event)

    subscription = @customer.subscriptions.find_by(processor_id: "sub_renewed_first")
    assert subscription.present?, "Expected handler to create subscription when no row exists"
    assert_equal "pro", subscription.name
    assert_equal "com.example.monthly", subscription.processor_plan
    assert_equal "active", subscription.status
    assert_equal "apple", subscription.data["store"]
    assert_kind_of Pay::Purchasekit::Subscription, subscription
  end
end
