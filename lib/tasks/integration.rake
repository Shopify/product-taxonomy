# frozen_string_literal: true

require "rake/testtask"

desc "Run integration tests"
Rake::TestTask.new(:integration) do |t|
  t.libs << "test"
  t.pattern = "test/integration/**/*_test.rb"
end
