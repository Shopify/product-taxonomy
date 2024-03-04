require 'bundler/setup'
Bundler.require(:default)

require 'sqlite3'
require 'active_record'

require_relative 'db/seed'

require_relative 'app/models/application_record'
require_relative 'app/models/category'
require_relative 'app/models/property'
require_relative 'app/models/property_value'

require_relative 'app/serializers/object_serializer'
require_relative 'app/serializers/data/category_serializer'
require_relative 'app/serializers/data/property_serializer'
require_relative 'app/serializers/data/property_value_serializer'
require_relative 'app/serializers/dist/json'
require_relative 'app/serializers/dist/text'

module Application
  ROOT = File.expand_path('..', __dir__)
  private_constant :ROOT

  class << self
    def root
      ROOT
    end

    def establish_db_connection!(env: :local)
      config = YAML.load_file('db/config.yml', aliases: true).fetch(env.to_s)
      unless config['database'] == ':memory:'
        config.merge!('database' => "#{root}/dev/tmp/#{config['database']}")
      end

      ActiveRecord::Base.establish_connection(config)
    end

    def load_and_reset_schema!
      require_relative('db/schema')
    end
  end
end
