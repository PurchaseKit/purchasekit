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

  def test_handles_missing_subscription_gracefully
    event = {
      "customer_id" => @customer.id,
      "subscription_id" => "sub_nonexistent",
      "store_product_id" => "com.example.monthly",
      "status" => "active",
      "current_period_start" => Time.current.iso8601,
      "current_period_end" => 1.month.from_now.iso8601,
      "ends_at" => nil
    }

    assert_nothing_raised { @handler.call(event) }
  end
end
