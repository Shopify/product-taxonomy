# frozen_string_literal: true

require_relative "../test_helper"

class ApplicationTest < ApplicationTestCase
  test "Zeitwerk compliance" do
    LOADER.eager_load(force: true)
  rescue Zeitwerk::NameError => e
    flunk(e.message)
  else
    assert(true)
  end

  test "Factories are valid" do
    FactoryBot.lint(traits: true)
  end
end
