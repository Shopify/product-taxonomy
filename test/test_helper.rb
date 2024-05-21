# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:test)

require "minitest/rails"
require "minitest/pride"
require_relative "../application"

Application.establish_db_connection!(env: :test)
Application.load_and_reset_schema!

FactoryBot.find_definitions

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    parallelize(workers: :number_of_processors)
  end
end
