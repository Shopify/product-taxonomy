# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "product_taxonomy-etl"
  
  # Extract version from git tag (e.g., etl-v1.2.0 -> 1.2.0)
  # Falls back to "0.0.0" if no matching tag is found
  spec.version       = `git describe --tags --match "etl-v*" 2>/dev/null`.strip.sub(/^etl-v/, '') || "0.0.0"
  
  spec.authors       = ["Shopify"]
  spec.email         = ["taxonomy@shopify.com"]

  spec.summary       = "ETL utilities for Shopify Product Taxonomy"
  spec.description   = "Code-only gem for processing Shopify Product Taxonomy data."
  spec.homepage      = "https://github.com/Shopify/product-taxonomy"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/Shopify/product-taxonomy/issues",
    "source_code_uri" => "https://github.com/Shopify/product-taxonomy",
    "allowed_push_host" => "https://rubygems.org",
  }

  spec.files         = Dir.glob("dev/lib/**/*")
  spec.require_paths = ["dev/lib"]

  # Runtime dependencies from dev/Gemfile
  spec.add_dependency "thor", "~> 1.4"
  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "activemodel", ">= 7.0"
  spec.add_dependency "json", "~> 2.16.0"
end

