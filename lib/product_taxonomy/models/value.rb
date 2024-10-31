# frozen_string_literal: true

module ProductTaxonomy
  class Value
    class << self
      def load_from_source(file: "data/values.yml")
        YAML.safe_load_file(file).each_with_object({}) do |value_data, value_hash|
          value_hash[value_data["friendly_id"]] = Value.new(
            id: value_data["id"],
            name: value_data["name"],
            friendly_id: value_data["friendly_id"],
            handle: value_data["handle"],
          )
        end
      end
    end

    attr_reader :id, :name, :friendly_id, :handle

    def initialize(id:, name:, friendly_id:, handle:)
      @id = id
      @name = name
      @friendly_id = friendly_id
      @handle = handle
    end
  end
end
