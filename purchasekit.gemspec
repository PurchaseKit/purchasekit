require_relative "lib/purchasekit/version"

Gem::Specification.new do |spec|
  spec.name = "purchasekit"
  spec.version = PurchaseKit::VERSION
  spec.authors = ["Joe Masilotti"]
  spec.email = ["joe@masilotti.com"]
  spec.homepage = "https://purchasekit.dev"
  spec.summary = "In-app purchase infrastructure for Rails"
  spec.description = "Receive normalized Apple and Google in-app purchase webhooks in your Rails app. Optionally integrates with the Pay gem automatically."
  spec.license = "LicenseRef-PurchaseKit"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/purchasekit/purchasekit"
  spec.metadata["changelog_uri"] = "https://github.com/purchasekit/purchasekit/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
      .reject { |f| f.end_with?("CLAUDE.md") }
  end

  spec.add_dependency "rails", ">= 7.0", "< 9"
  spec.add_dependency "httparty", "~> 0.22"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
