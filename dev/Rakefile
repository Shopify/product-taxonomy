# frozen_string_literal: true

require "minitest/test_task"

task default: ["test"]

Minitest::TestTask.create(:test) do |t|
  t.test_globs = [
    "test/unit/**/*_test.rb",
  ]
  t.warning = false
end

Minitest::TestTask.create(:test_integration) do |t|
  t.test_globs = [
    "test/integration/**/*_test.rb",
  ]
  t.warning = false
end
