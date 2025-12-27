require "test_helper"
require "ostruct"

class PurchaseKit::Pay::PaywallHelperTest < ActionView::TestCase
  include PurchaseKit::Pay::PaywallHelper

  fixtures "pay/customers"

  def setup
    @customer = pay_customers(:test_customer)
    @product = PurchaseKit::Product.new(
      id: "prod_TEST123",
      apple_product_id: "com.example.annual",
      google_product_id: "annual_subscription"
    )
  end

  # Mock the engine routes helper
  def purchasekit_pay
    OpenStruct.new(purchases_path: "/purchasekit/purchases")
  end

  # Mock main_app for default success_path
  def main_app
    OpenStruct.new(root_path: "/")
  end

  def test_purchasekit_paywall_renders_form_with_correct_attributes
    html = purchasekit_paywall(customer: @customer, success_path: "/dashboard") { "" }

    assert_match 'id="purchasekit_paywall"', html
    assert_match 'action="/purchasekit/purchases"', html
    assert_match 'data-controller="purchasekit-pay--paywall"', html
    assert_match "data-purchasekit-pay--paywall-customer-id-value=\"#{@customer.id}\"", html
  end

  def test_purchasekit_paywall_includes_hidden_fields
    html = purchasekit_paywall(customer: @customer, success_path: "/dashboard") { "" }

    assert_match 'name="customer_id"', html
    assert_match "value=\"#{@customer.id}\"", html
    assert_match 'name="success_path"', html
    assert_match 'value="/dashboard"', html
    assert_match 'name="environment"', html
    assert_match 'data-purchasekit-pay--paywall-target="environment"', html
  end

  def test_purchasekit_paywall_defaults_success_path_to_root
    html = purchasekit_paywall(customer: @customer) { "" }

    assert_match 'name="success_path"', html
    assert_match 'value="/"', html
  end

  def test_purchasekit_paywall_raises_without_customer
    assert_raises(ArgumentError) do
      purchasekit_paywall(customer: nil) { "" }
    end
  end

  def test_plan_option_renders_radio_and_label
    html = purchasekit_paywall(customer: @customer, success_path: "/") do |paywall|
      paywall.plan_option(product: @product, selected: true) { "Annual Plan" }
    end

    assert_match 'type="radio"', html
    assert_match 'name="product_id"', html
    assert_match "value=\"#{@product.id}\"", html
    assert_match 'checked="checked"', html
    assert_match 'data-purchasekit-pay--paywall-target="planRadio"', html
    assert_match "data-apple-store-product-id=\"#{@product.apple_product_id}\"", html
    assert_match "data-google-store-product-id=\"#{@product.google_product_id}\"", html
    assert_match "Annual Plan", html
  end

  def test_plan_option_not_selected_by_default
    html = purchasekit_paywall(customer: @customer, success_path: "/") do |paywall|
      paywall.plan_option(product: @product) { "Monthly" }
    end

    refute_match 'checked="checked"', html
  end

  def test_price_renders_span_with_data_attributes
    html = purchasekit_paywall(customer: @customer, success_path: "/") do |paywall|
      paywall.plan_option(product: @product) do
        paywall.price
      end
    end

    assert_match "<span", html
    assert_match 'data-purchasekit-pay--paywall-target="price"', html
    assert_match "data-apple-store-product-id=\"#{@product.apple_product_id}\"", html
    assert_match "data-google-store-product-id=\"#{@product.google_product_id}\"", html
    assert_match "Loading...", html
  end

  def test_price_with_custom_loading_content
    html = purchasekit_paywall(customer: @customer, success_path: "/") do |paywall|
      paywall.plan_option(product: @product) do
        paywall.price { "..." }
      end
    end

    assert_match "...", html
    refute_match "Loading...", html
  end

  def test_price_raises_outside_plan_option_block
    builder = PurchaseKit::Pay::PaywallBuilder.new(self, @customer)

    assert_raises(RuntimeError) do
      builder.price
    end
  end

  def test_submit_renders_disabled_button_with_data_attributes
    html = purchasekit_paywall(customer: @customer, success_path: "/") do |paywall|
      paywall.submit("Subscribe Now")
    end

    assert_match 'type="submit"', html
    assert_match 'value="Subscribe Now"', html
    assert_match 'disabled="disabled"', html
    assert_match 'data-purchasekit-pay--paywall-target="submitButton"', html
    assert_match 'data-turbo-submits-with="Subscribe Now"', html
  end

  def test_restore_link_renders_link_with_action
    html = purchasekit_paywall(customer: @customer, success_path: "/") do |paywall|
      paywall.restore_link
    end

    assert_match 'href="#"', html
    assert_match "purchasekit-pay--paywall#restore", html
    assert_match "Restore purchases", html
  end

  def test_restore_link_with_custom_text
    html = purchasekit_paywall(customer: @customer, success_path: "/") do |paywall|
      paywall.restore_link(text: "Already purchased?")
    end

    assert_match "Already purchased?", html
  end
end
