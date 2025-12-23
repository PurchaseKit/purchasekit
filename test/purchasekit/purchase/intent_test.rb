require "test_helper"

class PurchaseKit::Purchase::IntentTest < PurchaseKit::TestCase
  def test_create_returns_intent_with_uuid_and_product
    with_cassette("intent_create_success") do
      intent = PurchaseKit::Purchase::Intent.create(
        product_id: "prod_TEST123",
        customer_id: 1,
        success_path: "/paid",
        environment: "sandbox"
      )

      assert_equal "pi_TEST123", intent.id
      assert_match(/\A[0-9a-f-]+\z/i, intent.uuid)
      assert_kind_of PurchaseKit::Product, intent.product
      assert_equal "prod_TEST123", intent.product.id
    end
  end

  def test_create_raises_subscription_required_for_production_without_subscription
    with_cassette("intent_create_subscription_required") do
      error = assert_raises(PurchaseKit::Pay::SubscriptionRequiredError) do
        PurchaseKit::Purchase::Intent.create(
          product_id: "prod_TEST123",
          customer_id: 1,
          success_path: "/paid",
          environment: "production"
        )
      end

      assert_match(/Subscription required/, error.message)
    end
  end

  def test_create_raises_not_found_for_missing_product
    with_cassette("intent_create_not_found") do
      assert_raises(PurchaseKit::Pay::NotFoundError) do
        PurchaseKit::Purchase::Intent.create(
          product_id: "prod_MISSING",
          customer_id: 1,
          success_path: "/paid",
          environment: "sandbox"
        )
      end
    end
  end
end
