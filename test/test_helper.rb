# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/pride"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    parallelize workers: :number_of_processors
    fixtures :all

    self.use_transactional_tests = true
  end
end
