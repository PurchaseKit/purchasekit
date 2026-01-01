require "httparty"

module PurchaseKit
  # HTTP client for the PurchaseKit SaaS API.
  #
  # Used internally by Product and Purchase::Intent to communicate
  # with the PurchaseKit backend.
  #
  class ApiClient
    def get(path)
      request(:get, path)
    end

    def post(path, body = {})
      request(:post, path, body)
    end

    private

    def request(method, path, body = nil)
      options = {headers: headers}
      options[:body] = body.to_json if body

      HTTParty.public_send(method, url(path), options)
    end

    def url(path)
      "#{config.base_api_url}/apps/#{config.app_id}#{path}"
    end

    def headers
      {
        "Authorization" => "Bearer #{config.api_key}",
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }
    end

    def config
      PurchaseKit.config
    end
  end
end
