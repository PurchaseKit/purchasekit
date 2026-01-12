require "test_helper"
require "ostruct"

class PurchaseKit::PaywallHelperTest < ActionView::TestCase
  include PurchaseKit::PaywallHelper

  def setup
    @product = PurchaseKit::Product.new(
      id: "prod_TEST123",
      apple_product_id: "com.example.annual",
      google_product_id: "annual_subscription"
    )
  end

  # Mock the engine routes helper
  def purchase_kit
    OpenStruct.new(purchases_path: "/purchasekit/purchases")
  end

  # Mock main_app for default success_path
  def main_app
    OpenStruct.new(root_path: "/")
  end

  def test_purchasekit_paywall_renders_form_with_correct_attributes
    html = purchasekit_paywall(customer_id: 123, success_path: "/dashboard") { "" }

    assert_match 'id="purchasekit_paywall"', html
    assert_match 'action="/purchasekit/purchases"', html
    assert_match 'data-controller="purchasekit--paywall"', html
    assert_match 'data-purchasekit--paywall-customer-id-value="123"', html
  end

  def test_purchasekit_paywall_includes_hidden_fields
    html = purchasekit_paywall(customer_id: 123, success_path: "/dashboard") { "" }

    assert_match 'name="customer_id"', html
    assert_match 'value="123"', html
    assert_match 'name="success_path"', html
    assert_match 'value="/dashboard"', html
    assert_match 'name="environment"', html
    assert_match 'data-purchasekit--paywall-target="environment"', html
  end

  def test_purchasekit_paywall_defaults_success_path_to_root
    html = purchasekit_paywall(customer_id: 123) { "" }

    assert_match 'name="success_path"', html
    assert_match 'value="/"', html
  end

  def test_purchasekit_paywall_raises_without_customer_id
    assert_raises(ArgumentError) do
      purchasekit_paywall(customer_id: nil) { "" }
    end
  end

  def test_plan_option_renders_radio_and_label
    html = purchasekit_paywall(customer_id: 123, success_path: "/") do |paywall|
      paywall.plan_option(product: @product, selected: true) { "Annual Plan" }
    end

    assert_match 'type="radio"', html
    assert_match 'name="product_id"', html
    assert_match "value=\"#{@product.id}\"", html
    assert_match 'checked="checked"', html
    assert_match 'data-purchasekit--paywall-target="planRadio"', html
    assert_match "data-apple-store-product-id=\"#{@product.apple_product_id}\"", html
    assert_match "data-google-store-product-id=\"#{@product.google_product_id}\"", html
    assert_match "Annual Plan", html
  end

  def test_plan_option_not_selected_by_default
    html = purchasekit_paywall(customer_id: 123, success_path: "/") do |paywall|
      paywall.plan_option(product: @product) { "Monthly" }
    end

    refute_match 'checked="checked"', html
  end

  def test_price_renders_span_with_data_attributes
    html = purchasekit_paywall(customer_id: 123, success_path: "/") do |paywall|
      paywall.plan_option(product: @product) do
        paywall.price
      end
    end

    assert_match "<span", html
    assert_match 'data-purchasekit--paywall-target="price"', html
    assert_match "data-apple-store-product-id=\"#{@product.apple_product_id}\"", html
    assert_match "data-google-store-product-id=\"#{@product.google_product_id}\"", html
    assert_match "Loading...", html
  end

  def test_price_with_custom_loading_content
    html = purchasekit_paywall(customer_id: 123, success_path: "/") do |paywall|
      paywall.plan_option(product: @product) do
        paywall.price { "..." }
      end
    end

    assert_match "...", html
    refute_match "Loading...", html
  end

  def test_price_raises_outside_plan_option_block
    builder = PurchaseKit::PaywallBuilder.new(self)

    assert_raises(RuntimeError) do
      builder.price
    end
  end

  def test_submit_renders_disabled_button_with_data_attributes
    html = purchasekit_paywall(customer_id: 123, success_path: "/") do |paywall|
      paywall.submit("Subscribe Now")
    end

    assert_match 'type="submit"', html
    assert_match 'value="Subscribe Now"', html
    assert_match 'disabled="disabled"', html
    assert_match 'data-purchasekit--paywall-target="submitButton"', html
    assert_match 'data-turbo-submits-with="Subscribe Now"', html
  end

end
