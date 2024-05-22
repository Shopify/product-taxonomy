# frozen_string_literal: true

require_relative "boot"

require "active_record"
require "zeitwerk"
require "cgi"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, :development)

LOADER = Zeitwerk::Loader.new
LOADER.push_dir("#{__dir__}/../app/models")
LOADER.push_dir("#{__dir__}/../app/services")
LOADER.enable_reloading
LOADER.setup

module ProductTaxonomy
  class Application
    class << self
      def initialize!
        env = ENV["RAILS_ENV"] || "development"

        establish_db_connection!(env:)
      end

      def reset_schema!
        require_relative "../db/schema"
      end

      private

      def establish_db_connection!(env:)
        require "sqlite3"

        config = YAML.load_file("#{__dir__}/database.yml", aliases: true).fetch(env.to_s)
        ActiveRecord::Base.establish_connection(config)
      end
    end
  end
end
