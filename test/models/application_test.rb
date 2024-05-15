# frozen_string_literal: true

require_relative "../test_helper"

class ApplicationTest < ActiveSupport::TestCase
  test "Factories are valid" do
    FactoryBot.lint(traits: true)
  end
end
