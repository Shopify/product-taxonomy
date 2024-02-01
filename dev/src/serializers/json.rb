require 'json'

module Serializers
  class JSON
    def initialize(taxonomy, version)
      @taxonomy = taxonomy
      @version = version
    end

    def taxonomy
      output = {
        version: @version,
        verticals: @taxonomy.verticals.map do |vertical|
          root = vertical.first
          {
            name: root.name,
            prefix: root.id.downcase,
            categories: vertical.map(&:serialize_as_hash),
          }
        end,
        attributes: @taxonomy.attributes.map(&:serialize_as_hash),
      }
      ::JSON.pretty_generate(output)
    end

    def categories
      output = {
        version: @version,
        verticals: @taxonomy.verticals.map do |vertical|
          root = vertical.first
          {
            name: root.name,
            prefix: root.id.downcase,
            categories: vertical.map(&:serialize_as_hash),
          }
        end
      }
      ::JSON.pretty_generate(output)
    end

    def attributes
      output = @taxonomy.attributes.map(&:serialize_as_hash)
      ::JSON.pretty_generate(output)
    end
  end
end
