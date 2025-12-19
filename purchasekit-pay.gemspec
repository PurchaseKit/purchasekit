require_relative "lib/purchasekit/pay/version"

Gem::Specification.new do |spec|
  spec.name = "purchasekit-pay"
  spec.version = PurchaseKit::Pay::VERSION
  spec.authors = ["Joe Masilotti"]
  spec.email = ["joe@masilotti.com"]
  spec.homepage = "https://purchasekit.dev"
  spec.summary = "PurchaseKit payment processor for Pay"
  spec.description = "Add mobile in-app purchases to your Rails app with PurchaseKit and Pay."
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/purchasekit/purchasekit-pay"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "httparty"
  spec.add_dependency "pay", ">= 11.0"
  spec.add_dependency "rails", ">= 7.0"
end
