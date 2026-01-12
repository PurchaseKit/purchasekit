# Load the dummy Rails app
ENV["RAILS_ENV"] = "test"

# Suppress Pay gem's method redefinition warning
# Remove after https://github.com/pay-rails/pay/pull/1214 is released
$VERBOSE = nil
require_relative "dummy/config/environment"
$VERBOSE = true

require "rails/test_help"
require "minitest/autorun"
require "vcr"
require "webmock/minitest"

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("fixtures/vcr_cassettes", __dir__)
  config.hook_into :webmock
  config.default_cassette_options = {record: :once}

  # Filter sensitive data
  config.filter_sensitive_data("<API_KEY>") { PurchaseKit.config.api_key }
  config.filter_sensitive_data("<API_URL>") { PurchaseKit.config.api_url }
end

# Configure PurchaseKit with test values
PurchaseKit.configure do |config|
  config.api_url = "http://localhost:3000"
  config.api_key = "sk_test_key"
  config.app_id = "app_TEST123"
  config.webhook_secret = "whsec_test_secret"
end

module PurchaseKit
  class TestCase < Minitest::Test
    # Helper to use VCR cassettes
    def with_cassette(name, &block)
      VCR.use_cassette(name, &block)
    end
  end
end

# ActiveRecord test case with fixtures
class ActiveSupport::TestCase
  self.fixture_paths = [File.expand_path("fixtures", __dir__)]
  self.use_transactional_tests = true
  self.use_instantiated_fixtures = false
end
