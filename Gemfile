# frozen_string_literal: true

source "https://rubygems.org"

# core app
gem "rails", "~> 7.1.3", ">= 7.1.3.2"
gem "sqlite3", "~> 1.7"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: [:windows, :jruby]

gem "bootsnap", require: false
gem "rubocop-shopify", require: false

# docs
gem "jekyll", "~> 4.3"
gem "jekyll-redirect-from", "~> 0.16"

# command line
gem "cli-ui", "~> 2.2"
gem "tty-option", "~> 0.3"

# generate taxonomy mappings
gem "qdrant-ruby", require: "qdrant"
gem "ruby-openai"

group :development, :test do
  gem "debug", platforms: [:mri, :windows]
  gem "mocha"
  gem "factory_bot_rails", "~> 6.4"
  gem "minitest-hooks", "~> 1.5"
end
