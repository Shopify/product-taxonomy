require 'bundler/setup'
Bundler.require(:default)

require_relative 'db/connection'
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
  end
end
