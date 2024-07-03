# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 7.1.3", ">= 7.1.3.2"
gem "sqlite3", "~> 1.7"
gem "puma", ">= 5.0"
gem "jekyll", "~> 4.3"
gem "tzinfo-data", platforms: [:windows, :jruby]

gem "bootsnap", require: false
gem "rubocop-shopify", require: false

group :optional, optional: true do
  source "https://pkgs.shopify.io/basic/gems/ruby" do
    gem "filter_values_sorter"
  end
end

group :development, :test do
  gem "debug", platforms: [:mri, :windows]
  gem "mocha"
  gem "factory_bot_rails", "~> 6.4"
  gem "minitest-hooks", "~> 1.5"
end
