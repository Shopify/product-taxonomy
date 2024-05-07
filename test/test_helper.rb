# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:test)

require "minitest/rails"
require "minitest/pride"
require_relative "../application"

Application.establish_db_connection!(env: :test)
Application.load_and_reset_schema!

FactoryBot.find_definitions

class ApplicationTestCase < ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include Minitest::Hooks

  def around_all
    ActiveRecord::Base.transaction do
      super
    end
  end
end
