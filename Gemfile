# frozen_string_literal: true

source "https://rubygems.org"

# core app

gem "rubocop-shopify", require: false

# docs
gem "jekyll", "~> 4.3"
gem "jekyll-redirect-from", "~> 0.16"

# command line
gem "cli-ui", "~> 2.2", require: false
gem "tty-option", "~> 0.3", require: false

# generate taxonomy mappings
gem "qdrant-ruby", require: "qdrant"
gem "ruby-openai"
gem "dotenv", groups: [:development, :test]

group :development, :test do
  gem "debug", platforms: [:mri, :windows]
  gem "mocha"
  gem "factory_bot", "~> 6.4"
  gem "minitest-hooks", "~> 1.5"
end
