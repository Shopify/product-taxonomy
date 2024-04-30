# frozen_string_literal: true

require "bundler/setup"

Bundler.require(:test)
require_relative "../application"
Application.establish_db_connection!(env: :test)
Application.load_and_reset_schema!

require "minitest/autorun"
require "minitest/pride"
