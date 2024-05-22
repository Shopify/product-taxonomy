# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
Bundler.require(:test)

ProductTaxonomy::Application.reset_schema!

require "minitest/autorun"
require "minitest/pride"
require "active_support/test_case"

FactoryBot.find_definitions

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    parallelize workers: :number_of_processors
  end
end
