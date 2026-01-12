require "test_helper"

class PurchaseKit::ApiClientTest < PurchaseKit::TestCase
  def setup
    @client = PurchaseKit::ApiClient.new
  end

  def test_get_makes_request_with_correct_url
    with_cassette("product_find_success") do
      response = @client.get("/products/prod_TEST123")

      assert response.success?
      assert_equal 200, response.code
    end
  end

  def test_post_makes_request_with_correct_url_and_body
    with_cassette("intent_create_success") do
      response = @client.post("/purchase/intents", {
        product_id: "prod_TEST123",
        customer_id: 1,
        success_path: "/paid",
        environment: "sandbox"
      })

      assert response.success?
      assert_equal 201, response.code
    end
  end

  def test_request_includes_authorization_header
    stub_request(:get, /.*/)
      .to_return(status: 200, body: "{}")

    @client.get("/test")

    assert_requested :get, /.*/, headers: {
      "Authorization" => "Bearer #{PurchaseKit.config.api_key}"
    }
  end

  def test_request_includes_content_type_headers
    stub_request(:get, /.*/)
      .to_return(status: 200, body: "{}")

    @client.get("/test")

    assert_requested :get, /.*/, headers: {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
  end

  def test_url_includes_app_id
    stub_request(:get, /.*/)
      .to_return(status: 200, body: "{}")

    @client.get("/products/123")

    expected_url = "#{PurchaseKit.config.api_url}/api/v1/apps/#{PurchaseKit.config.app_id}/products/123"
    assert_requested :get, expected_url
  end

  def test_post_sends_json_body
    stub_request(:post, /.*/)
      .to_return(status: 201, body: "{}")

    @client.post("/test", {foo: "bar"})

    assert_requested :post, /.*/, body: '{"foo":"bar"}'
  end
end
