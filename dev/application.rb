require 'bundler/setup'
Bundler.require(:default)

require_relative 'db/schema'
require_relative 'db/seed'

require_relative 'app/models/application_record'
require_relative 'app/models/category'
require_relative 'app/models/property'
require_relative 'app/models/property_value'
require_relative 'app/serializers/json'
require_relative 'app/serializers/text'

module Application
  ROOT = File.expand_path('..', __dir__)
  private_constant :ROOT

  class << self
    def root
      ROOT
    end
  end
end
