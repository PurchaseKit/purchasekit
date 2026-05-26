require "standalone_test_helper"

class EventCallbacksTest < PurchaseKit::StandaloneTestCase
  def setup
    @original_config = PurchaseKit.config
    PurchaseKit.reset_config!
    @callbacks_fired = []
  end

  def teardown
    # Reset config
    PurchaseKit.reset_config!
    PurchaseKit.configure do |config|
      config.api_url = "http://localhost:3000"
      config.api_key = "sk_test_key"
      config.app_id = "app_TEST123"
      config.webhook_secret = "whsec_test_secret"
    end
  end

  def test_subscription_created_callback_fires
    PurchaseKit.configure do |config|
      config.on(:subscription_created) do |event|
        @callbacks_fired << [:subscription_created, event]
      end
    end

    event_data = {
      "type" => "subscription.created",
      "event_id" => "evt_123",
      "customer_id" => 1,
      "subscription_id" => "sub_new123",
      "store" => "apple",
      "store_product_id" => "com.example.annual",
      "status" => "active"
    }

    # Can't call Events.publish without Rails/ActionCable, so test the callback directly
    handlers = PurchaseKit.config.handlers_for(:subscription_created)
    event = PurchaseKit::Events::Event.new(type: :subscription_created, payload: event_data)
    handlers.each { |h| h.call(event) }

    assert_equal 1, @callbacks_fired.count
    assert_equal :subscription_created, @callbacks_fired.first[0]
    assert_equal "sub_new123", @callbacks_fired.first[1].subscription_id
  end

  def test_subscription_canceled_callback_fires
    PurchaseKit.configure do |config|
      config.on(:subscription_canceled) do |event|
        @callbacks_fired << [:subscription_canceled, event]
      end
    end

    event_data = {
      "type" => "subscription.canceled",
      "subscription_id" => "sub_123",
      "status" => "canceled",
      "ends_at" => "2025-02-01T00:00:00Z"
    }

    handlers = PurchaseKit.config.handlers_for(:subscription_canceled)
    event = PurchaseKit::Events::Event.new(type: :subscription_canceled, payload: event_data)
    handlers.each { |h| h.call(event) }

    assert_equal 1, @callbacks_fired.count
    assert_equal :subscription_canceled, @callbacks_fired.first[0]
  end

  def test_event_provides_parsed_time_fields
    event_data = {
      "current_period_start" => "2025-01-01T00:00:00Z",
      "current_period_end" => "2026-01-01T00:00:00Z",
      "ends_at" => "2025-06-01T00:00:00Z"
    }

    event = PurchaseKit::Events::Event.new(type: :subscription_created, payload: event_data)

    assert_kind_of Time, event.current_period_start
    assert_kind_of Time, event.current_period_end
    assert_kind_of Time, event.ends_at
  end

  def test_event_provides_parsed_trial_ends_at
    event_data = {
      "trial_ends_at" => "2025-01-08T00:00:00Z"
    }

    event = PurchaseKit::Events::Event.new(type: :subscription_created, payload: event_data)

    assert_kind_of Time, event.trial_ends_at
  end

  def test_event_exposes_google_base_plan_id
    event_data = {
      "store" => "google",
      "store_product_id" => "com.example.pro",
      "google_base_plan_id" => "annual"
    }

    event = PurchaseKit::Events::Event.new(type: :subscription_created, payload: event_data)

    assert_equal "annual", event.google_base_plan_id
  end

  def test_event_google_base_plan_id_is_nil_when_missing
    event = PurchaseKit::Events::Event.new(type: :subscription_created, payload: {"store" => "apple"})

    assert_nil event.google_base_plan_id
  end

  def test_event_handles_nil_time_fields
    event_data = {
      "current_period_start" => nil,
      "ends_at" => nil,
      "trial_ends_at" => nil
    }

    event = PurchaseKit::Events::Event.new(type: :subscription_created, payload: event_data)

    assert_nil event.current_period_start
    assert_nil event.ends_at
    assert_nil event.trial_ends_at
  end
end
