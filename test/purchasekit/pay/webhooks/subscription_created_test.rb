require "test_helper"

class PurchaseKit::Pay::Webhooks::SubscriptionCreatedTest < ActiveSupport::TestCase
  fixtures "pay/customers", "pay/subscriptions"

  def setup
    @handler = PurchaseKit::Pay::Webhooks::SubscriptionCreated.new
    @customer = pay_customers(:test_customer)
  end

  def test_creates_new_subscription_and_broadcasts_redirect
    event = {
      "customer_id" => @customer.id,
      "subscription_id" => "sub_new123",
      "store" => "apple",
      "store_product_id" => "com.example.annual",
      "subscription_name" => "pro",
      "status" => "active",
      "current_period_start" => Time.current.iso8601,
      "current_period_end" => 1.year.from_now.iso8601,
      "ends_at" => nil,
      "success_path" => "/dashboard"
    }

    broadcast_called = false
    Turbo::StreamsChannel.stub :broadcast_stream_to, ->(*args) { broadcast_called = true } do
      @handler.call(event)
    end

    subscription = @customer.subscriptions.find_by(processor_id: "sub_new123")
    assert subscription.present?
    assert_equal "pro", subscription.name
    assert_equal "com.example.annual", subscription.processor_plan
    assert_equal "active", subscription.status
    assert_equal "apple", subscription.data["store"]
    assert_kind_of Pay::Purchasekit::Subscription, subscription
    assert broadcast_called, "Expected Turbo broadcast to be called for new subscription"
  end

  def test_updates_existing_subscription_without_broadcast
    existing = pay_subscriptions(:existing_subscription)
    event = {
      "customer_id" => @customer.id,
      "subscription_id" => existing.processor_id,
      "store" => "apple",
      "store_product_id" => "com.example.monthly",
      "subscription_name" => "pro",
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

    existing.reload
    assert_equal "com.example.monthly", existing.processor_plan
    assert_equal "apple", existing.data["store"]
    refute broadcast_called, "Expected no broadcast for existing subscription"
  end

  def test_subscription_methods_raise_appropriate_errors
    event = {
      "customer_id" => @customer.id,
      "subscription_id" => "sub_sti_test",
      "store" => "apple",
      "store_product_id" => "com.example.annual",
      "subscription_name" => "pro",
      "status" => "active",
      "current_period_start" => Time.current.iso8601,
      "current_period_end" => 1.year.from_now.iso8601,
      "ends_at" => nil,
      "success_path" => "/dashboard"
    }

    Turbo::StreamsChannel.stub :broadcast_stream_to, ->(*args) {} do
      @handler.call(event)
    end

    subscription = Pay::Subscription.find_by(processor_id: "sub_sti_test")

    error = assert_raises(Pay::Purchasekit::Error) { subscription.cancel }
    assert_equal "Cancel through App Store or Google Play.", error.message
  end

  def test_stores_google_store_in_data
    event = {
      "customer_id" => @customer.id,
      "subscription_id" => "sub_google123",
      "store" => "google",
      "store_product_id" => "annual_subscription",
      "subscription_name" => "pro",
      "status" => "active",
      "current_period_start" => Time.current.iso8601,
      "current_period_end" => 1.year.from_now.iso8601,
      "ends_at" => nil,
      "success_path" => "/paid"
    }

    Turbo::StreamsChannel.stub :broadcast_stream_to, ->(*args) {} do
      @handler.call(event)
    end

    subscription = @customer.subscriptions.find_by(processor_id: "sub_google123")
    assert_equal "google", subscription.data["store"]
  end
end
