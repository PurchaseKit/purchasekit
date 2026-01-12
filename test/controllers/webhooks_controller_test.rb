require "test_helper"

class PurchaseKit::WebhooksControllerTest < ActionDispatch::IntegrationTest
  fixtures "pay/customers"

  def setup
    @customer = pay_customers(:test_customer)
    @event = {
      type: "subscription.created",
      customer_id: @customer.id,
      subscription_id: "sub_123",
      store: "apple",
      store_product_id: "com.example.annual",
      subscription_name: "pro",
      status: "active",
      current_period_start: Time.current.iso8601,
      current_period_end: 1.year.from_now.iso8601,
      success_path: "/dashboard"
    }
    @payload = @event.to_json
    @secret = PurchaseKit.config.webhook_secret
  end

  def test_accepts_valid_signature
    signature = OpenSSL::HMAC.hexdigest("SHA256", @secret, @payload)

    assert_difference "Pay::Webhook.count", 1 do
      post "/purchasekit/webhooks",
        params: @payload,
        headers: {
          "Content-Type" => "application/json",
          "X-PurchaseKit-Signature" => signature
        }
    end

    assert_response :ok
  end

  def test_rejects_invalid_signature
    assert_no_difference "Pay::Webhook.count" do
      post "/purchasekit/webhooks",
        params: @payload,
        headers: {
          "Content-Type" => "application/json",
          "X-PurchaseKit-Signature" => "invalid_signature"
        }
    end

    assert_response :bad_request
  end

  def test_rejects_missing_signature
    assert_no_difference "Pay::Webhook.count" do
      post "/purchasekit/webhooks",
        params: @payload,
        headers: {"Content-Type" => "application/json"}
    end

    assert_response :bad_request
  end

  def test_accepts_request_without_signature_when_secret_blank_in_development
    original_secret = PurchaseKit.config.webhook_secret
    PurchaseKit.config.webhook_secret = nil

    assert_difference "Pay::Webhook.count", 1 do
      post "/purchasekit/webhooks",
        params: @payload,
        headers: {"Content-Type" => "application/json"}
    end

    assert_response :ok
  ensure
    PurchaseKit.config.webhook_secret = original_secret
  end

  def test_rejects_request_when_secret_blank_in_production
    original_secret = PurchaseKit.config.webhook_secret
    PurchaseKit.config.webhook_secret = nil

    Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
      assert_no_difference "Pay::Webhook.count" do
        post "/purchasekit/webhooks",
          params: @payload,
          headers: {"Content-Type" => "application/json"}
      end

      assert_response :bad_request
    end
  ensure
    PurchaseKit.config.webhook_secret = original_secret
  end

  def test_ignores_unregistered_event_types
    unregistered_event = {type: "unknown.event"}.to_json
    signature = OpenSSL::HMAC.hexdigest("SHA256", @secret, unregistered_event)

    assert_no_difference "Pay::Webhook.count" do
      post "/purchasekit/webhooks",
        params: unregistered_event,
        headers: {
          "Content-Type" => "application/json",
          "X-PurchaseKit-Signature" => signature
        }
    end

    assert_response :ok
  end

  def test_creates_webhook_record_with_correct_attributes
    signature = OpenSSL::HMAC.hexdigest("SHA256", @secret, @payload)

    post "/purchasekit/webhooks",
      params: @payload,
      headers: {
        "Content-Type" => "application/json",
        "X-PurchaseKit-Signature" => signature
      }

    webhook = Pay::Webhook.last
    assert_equal "purchasekit", webhook.processor
    assert_equal "subscription.created", webhook.event_type
    assert_equal @customer.id.to_s, webhook.event["customer_id"].to_s
  end
end
