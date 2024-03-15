# frozen_string_literal: true

Bundler.require(:test)
require_relative "../application"
Application.establish_db_connection!(env: :test)
Application.load_and_reset_schema!

require "minitest/autorun"
require "minitest/pride"
