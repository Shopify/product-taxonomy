# frozen_string_literal: true

module ProductTaxonomy
  class Attribute
    include ActiveModel::Validations

    class << self
      def load_from_source(values:, file: "data/attributes.yml")
        parsed_yaml = YAML.safe_load_file(file)
        attributes = parsed_yaml["base_attributes"].each_with_object({}) do |attribute_data, attribute_hash|
          attribute_hash[attribute_data["friendly_id"]] = Attribute.new(
            id: attribute_data["id"],
            name: attribute_data["name"],
            description: attribute_data["description"],
            friendly_id: attribute_data["friendly_id"],
            handle: attribute_data["handle"],
            values: attribute_data["values"]&.map { values[_1] },
          )
        end
        parsed_yaml["extended_attributes"].each_with_object(attributes) do |attribute_data, attribute_hash|
          attribute_hash[attribute_data["friendly_id"]] = ExtendedAttribute.new(
            name: attribute_data["name"],
            handle: attribute_data["handle"],
            description: attribute_data["description"],
            friendly_id: attribute_data["friendly_id"],
            values_from: attribute_hash[attribute_data["values_from"]],
          )
        end
      end
    end

    attr_reader :id, :name, :description, :friendly_id, :handle, :values

    validates :name, presence: true
    validates :friendly_id, presence: true
    validates :handle, presence: true
    validates :description, presence: true

    def initialize(id:, name:, description:, friendly_id:, handle:, values:)
      @id = id
      @name = name
      @description = description
      @friendly_id = friendly_id
      @handle = handle
      @values = values
    end
  end
end
