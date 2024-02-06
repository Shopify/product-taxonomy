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
        verticals:,
        attributes: @taxonomy.attributes.map(&:serialize_as_hash),
      }
      ::JSON.pretty_generate(output)
    end

    def categories
      output = {
        version: @version,
        verticals:,
      }
      ::JSON.pretty_generate(output)
    end

    def attributes
      output = {
        version: @version,
        attributes: @taxonomy.attributes.map(&:serialize_as_hash),
      }
      ::JSON.pretty_generate(output)
    end

    private

    def verticals
      @taxonomy.verticals.map do |root|
        {
          name: root.name,
          prefix: root.id.downcase,
          categories: root.descendants_and_self.map(&:serialize_as_hash),
        }
      end
    end
  end
end
