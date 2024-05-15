# frozen_string_literal: true

require "cgi"
require "fileutils"
require "json"
require "yaml"

# require "bundler/setup"
# Bundler.require(:default)

# require "active_record"
# require "zeitwerk"

# LOADER = Zeitwerk::Loader.new
# LOADER.push_dir("#{__dir__}/app/models")
# LOADER.push_dir("#{__dir__}/app/services")
# LOADER.enable_reloading
# LOADER.setup

module Application
  ROOT = File.expand_path(__dir__)
  private_constant :ROOT

  class << self
    def root
      ROOT
    end

    def establish_db_connection!(env: :local)
      puts "=== STOP establish_db_connection"
      # require "sqlite3"

      # config = YAML.load_file("#{root}/db/config.yml", aliases: true).fetch(env.to_s)
      # unless config["database"] == ":memory:"
      #   config.merge!("database" => "#{root}/tmp/#{config["database"]}")
      # end

      # ActiveRecord::Base.establish_connection(config)
    end

    def load_and_reset_schema!
      puts "=== STOP load_and_reset_schema"
      # require_relative("db/schema")
    end
  end
end
