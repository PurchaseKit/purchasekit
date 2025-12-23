require "test_helper"

class PurchaseKit::Pay::PurchasesControllerTest < ActionDispatch::IntegrationTest
  fixtures "pay/customers"

  def setup
    @customer = pay_customers(:test_customer)
  end

  def test_create_returns_turbo_stream_with_intent_data
    VCR.use_cassette("purchases_create_success") do
      post "/purchasekit/purchases",
        params: {
          customer_id: @customer.id,
          product_id: "prod_TEST123",
          success_path: "/dashboard",
          environment: "sandbox"
        },
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      assert_response :success
      assert_match "turbo-stream", response.body
      assert_match "purchasekit_paywall", response.body
      assert_match "data-correlation-id", response.body
      assert_match "data-apple-store-product-id", response.body
    end
  end

  def test_create_handles_subscription_required_error
    VCR.use_cassette("purchases_create_subscription_required") do
      post "/purchasekit/purchases",
        params: {
          customer_id: @customer.id,
          product_id: "prod_TEST123",
          success_path: "/dashboard",
          environment: "production"
        },
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      assert_response :success
      assert_match "turbo-stream", response.body
      assert_match "purchasekit_paywall", response.body
      assert_match "purchasekit-error", response.body
    end
  end

  def test_create_returns_not_found_for_missing_customer
    post "/purchasekit/purchases",
      params: {
        customer_id: 999999,
        product_id: "prod_TEST123",
        success_path: "/dashboard",
        environment: "sandbox"
      },
      headers: {"Accept" => "text/vnd.turbo-stream.html"}

    assert_response :not_found
  end
end
