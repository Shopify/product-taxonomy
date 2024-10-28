# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "minitest/pride"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    parallelize workers: :number_of_processors
    fixtures :all

    self.use_transactional_tests = true
  end
end
