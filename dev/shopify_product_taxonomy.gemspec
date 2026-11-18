# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "shopify_product_taxonomy"

  require_relative "lib/product_taxonomy/version"
  spec.version       = ProductTaxonomy::VERSION
  
  spec.authors       = ["Shopify"]
  spec.email         = ["gems@shopify.com"]

  spec.summary       = "Load the complete Shopify Standard Product Taxonomy into memory as a tree "
  spec.description   = "A code-only gem providing Ruby classes and utilities to parse and process " \
                       "Shopify's Standard Product Taxonomy data " \
                       "from YAML source files into an in-memory Ruby object model. " \
                       "Data files are available at https://github.com/Shopify/product-taxonomy"
  spec.homepage      = "https://github.com/Shopify/product-taxonomy"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/Shopify/product-taxonomy/issues",
    "source_code_uri" => "https://github.com/Shopify/product-taxonomy",
    "allowed_push_host" => "https://rubygems.org",
  }

  spec.files         = Dir.glob("lib/**/*").reject { |f| f.start_with?("lib/product_taxonomy/commands") || f == "lib/product_taxonomy/cli.rb" }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "activemodel", ">= 7.0"
  spec.add_dependency "json", ">= 2.16", "< 2.19"
end

