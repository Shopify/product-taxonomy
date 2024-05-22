# frozen_string_literal: true

require "rake/testtask"

desc "Run unit tests"
Rake::TestTask.new(:unit) do |t|
  t.libs << "test"
  t.pattern = "test/models/**/*_test.rb"
end
