require "test_helper"

class PurchaseKit::ConfigurationTest < Minitest::Test
  def test_default_api_url
    config = PurchaseKit::Configuration.new

    assert_equal "https://purchasekit.dev", config.api_url
  end

  def test_api_url_is_configurable
    config = PurchaseKit::Configuration.new
    config.api_url = "http://localhost:3000"

    assert_equal "http://localhost:3000", config.api_url
  end

  def test_api_key_is_configurable
    config = PurchaseKit::Configuration.new
    config.api_key = "sk_test_key"

    assert_equal "sk_test_key", config.api_key
  end

  def test_app_id_is_configurable
    config = PurchaseKit::Configuration.new
    config.app_id = "app_TEST123"

    assert_equal "app_TEST123", config.app_id
  end

  def test_webhook_secret_is_configurable
    config = PurchaseKit::Configuration.new
    config.webhook_secret = "whsec_test"

    assert_equal "whsec_test", config.webhook_secret
  end

  def test_configure_block_yields_config
    original_config = PurchaseKit.config.dup
    PurchaseKit.reset_config!

    PurchaseKit.configure do |config|
      config.api_key = "new_key"
      config.app_id = "new_app"
    end

    assert_equal "new_key", PurchaseKit.config.api_key
    assert_equal "new_app", PurchaseKit.config.app_id
  ensure
    PurchaseKit.instance_variable_set(:@config, original_config)
  end

  def test_config_returns_same_instance
    config1 = PurchaseKit.config
    config2 = PurchaseKit.config

    assert_same config1, config2
  end

  def test_demo_mode_defaults_to_false
    config = PurchaseKit::Configuration.new

    refute config.demo_mode?
  end

  def test_demo_mode_is_configurable
    config = PurchaseKit::Configuration.new
    config.demo_mode = true

    assert config.demo_mode?
  end

  def test_base_api_url_includes_api_version
    config = PurchaseKit::Configuration.new

    assert_equal "https://purchasekit.dev/api/v1", config.base_api_url
  end
end
