# frozen_string_literal: true

require_relative "../test_helper"

class ApplicationTest < ActiveSupport::TestCase
  test "Zeitwerk compliance" do
    LOADER.eager_load(force: true)
  rescue Zeitwerk::NameError => e
    flunk(e.message)
  else
    assert(true)
  end
end
