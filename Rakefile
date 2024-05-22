# frozen_string_literal: true

require_relative "config/application"
require "rake/testtask"

task default: ["test"]

namespace :db do
  desc "Load the database schema"
  task :schema_load do
    require_relative "config/environment"
    load("db/schema.rb")
  end

  desc "Drop the database"
  task :drop do
    require_relative "config/environment"
    ActiveRecord::Tasks::DatabaseTasks.drop_current
  end
end

desc "Run all tests"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

desc "Run unit tests"
Rake::TestTask.new(:unit) do |t|
  t.libs << "test"
  t.pattern = "test/models/**/*_test.rb"
end

desc "Run integration tests"
Rake::TestTask.new(:integration) do |t|
  t.libs << "test"
  t.pattern = "test/integration/**/*_test.rb"
end
