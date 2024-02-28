Bundler.require(:test)
require_relative '../application'
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)
require_relative '../db/schema'

require 'minitest/autorun'
require 'minitest/pride'
