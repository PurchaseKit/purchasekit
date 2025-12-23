require "test_helper"

class PurchaseKit::ProductTest < PurchaseKit::TestCase
  def test_find_returns_product_with_both_platform_ids
    with_cassette("product_find_success") do
      product = PurchaseKit::Product.find("prod_TEST123")

      assert_equal "prod_TEST123", product.id
      assert_equal "com.example.annual", product.apple_product_id
      assert_equal "annual_subscription", product.google_product_id
    end
  end

  def test_find_raises_not_found_error_for_missing_product
    with_cassette("product_find_not_found") do
      error = assert_raises(PurchaseKit::Pay::NotFoundError) do
        PurchaseKit::Product.find("prod_MISSING")
      end

      assert_match(/Product not found/, error.message)
    end
  end

  def test_find_raises_error_for_api_failure
    with_cassette("product_find_error") do
      assert_raises(PurchaseKit::Pay::Error) do
        PurchaseKit::Product.find("prod_ERROR")
      end
    end
  end

  def test_store_product_id_returns_apple_id_for_apple_platform
    product = PurchaseKit::Product.new(
      id: "prod_TEST",
      apple_product_id: "com.example.monthly",
      google_product_id: "monthly_sub"
    )

    assert_equal "com.example.monthly", product.store_product_id(platform: :apple)
  end

  def test_store_product_id_returns_google_id_for_google_platform
    product = PurchaseKit::Product.new(
      id: "prod_TEST",
      apple_product_id: "com.example.monthly",
      google_product_id: "monthly_sub"
    )

    assert_equal "monthly_sub", product.store_product_id(platform: :google)
  end

  def test_store_product_id_raises_for_unknown_platform
    product = PurchaseKit::Product.new(id: "prod_TEST")

    assert_raises(ArgumentError) do
      product.store_product_id(platform: :unknown)
    end
  end
end
