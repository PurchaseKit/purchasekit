# Use the main gem's Gemfile for bundler setup
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../../../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
