require "test_helper"

class PurchaseKit::Pay::ConfigurationTest < Minitest::Test
  def test_default_api_url
    config = PurchaseKit::Pay::Configuration.new

    assert_equal "https://purchasekit.dev", config.api_url
  end

  def test_api_url_is_configurable
    config = PurchaseKit::Pay::Configuration.new
    config.api_url = "http://localhost:3000"

    assert_equal "http://localhost:3000", config.api_url
  end

  def test_api_key_is_configurable
    config = PurchaseKit::Pay::Configuration.new
    config.api_key = "sk_test_key"

    assert_equal "sk_test_key", config.api_key
  end

  def test_app_id_is_configurable
    config = PurchaseKit::Pay::Configuration.new
    config.app_id = "app_TEST123"

    assert_equal "app_TEST123", config.app_id
  end

  def test_webhook_secret_is_configurable
    config = PurchaseKit::Pay::Configuration.new
    config.webhook_secret = "whsec_test"

    assert_equal "whsec_test", config.webhook_secret
  end

  def test_configure_block_yields_config
    original_config = PurchaseKit::Pay.config.dup
    PurchaseKit::Pay.config = PurchaseKit::Pay::Configuration.new

    PurchaseKit::Pay.configure do |config|
      config.api_key = "new_key"
      config.app_id = "new_app"
    end

    assert_equal "new_key", PurchaseKit::Pay.config.api_key
    assert_equal "new_app", PurchaseKit::Pay.config.app_id
  ensure
    PurchaseKit::Pay.config = original_config
  end

  def test_config_returns_same_instance
    config1 = PurchaseKit::Pay.config
    config2 = PurchaseKit::Pay.config

    assert_same config1, config2
  end
end
