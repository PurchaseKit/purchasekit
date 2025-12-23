require "test_helper"

class PurchaseKit::Pay::WebhookTest < ActiveSupport::TestCase
  def test_queue_creates_webhook_record_and_enqueues_job
    event = {type: "subscription.created", customer_id: 1}

    assert_difference "Pay::Webhook.count", 1 do
      PurchaseKit::Pay::Webhook.queue(event)
    end

    webhook = Pay::Webhook.last
    assert_equal "purchasekit", webhook.processor
    assert_equal "subscription.created", webhook.event_type
    assert_equal event.stringify_keys, webhook.event
  end

  def test_queue_skips_unregistered_event_types
    event = {type: "unknown.event", customer_id: 1}

    assert_no_difference "Pay::Webhook.count" do
      PurchaseKit::Pay::Webhook.queue(event)
    end
  end
end
