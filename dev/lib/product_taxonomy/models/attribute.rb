# frozen_string_literal: true

module ProductTaxonomy
  class Attribute
    include ActiveModel::Validations

    class << self
      # Load attributes from source data. By default, this data is deserialized from a YAML file in the `data` directory.
      #
      # @param source_data [Array<Hash>] The source data to load attributes from.
      # @param values [Hash<String, Value>] A hash of {Value} objects keyed by their friendly ID.
      # @return [ModelIndex<Attribute>] A model index of {Attribute} objects.
      def load_from_source(source_data:, values:)
        model_index = ModelIndex.new(self, hashed_by: :friendly_id)
        raise ArgumentError, "source_data must be a hash" unless source_data.is_a?(Hash)
        raise ArgumentError, "source_data must contain keys \"base_attributes\" and \"extended_attributes\"" unless
          source_data.keys.sort == ["base_attributes", "extended_attributes"]

        ["base_attributes", "extended_attributes"].each do |type|
          load_attributes(type, source_data, model_index, values)
        end

        model_index
      end

      private

      def load_attributes(type, source_data, model_index, values)
        source_data[type].each do |attribute_data|
          raise ArgumentError, "source_data must contain hashes" unless attribute_data.is_a?(Hash)

          attribute = if type == "base_attributes"
            values_by_friendly_id = attribute_data["values"]&.map { values[_1] || _1 }
            Attribute.new(
              id: attribute_data["id"],
              name: attribute_data["name"],
              description: attribute_data["description"],
              friendly_id: attribute_data["friendly_id"],
              handle: attribute_data["handle"],
              values: values_by_friendly_id,
              uniqueness_context: model_index,
            )
          else
            value_friendly_id = attribute_data["values_from"]
            ExtendedAttribute.new(
              name: attribute_data["name"],
              handle: attribute_data["handle"],
              description: attribute_data["description"],
              friendly_id: attribute_data["friendly_id"],
              values_from: model_index.hashed_by(:friendly_id)[value_friendly_id] || value_friendly_id,
              uniqueness_context: model_index,
            )
          end

          attribute.validate!
          model_index.add(attribute)
        end
      end
    end

    validates :id, presence: true, numericality: { only_integer: true }, if: -> { self.class == Attribute }
    validates :name, presence: true
    validates :friendly_id, presence: true
    validates :handle, presence: true
    validates :description, presence: true
    validates :values, presence: true, if: -> { self.class == Attribute }
    validates_with ProductTaxonomy::ModelIndex::UniquenessValidator, attributes: [:friendly_id]
    validate :values_valid?

    attr_reader :id, :name, :description, :friendly_id, :handle, :values, :uniqueness_context

    # @param id [Integer] The ID of the attribute.
    # @param name [String] The name of the attribute.
    # @param description [String] The description of the attribute.
    # @param friendly_id [String] The friendly ID of the attribute.
    # @param handle [String] The handle of the attribute.
    # @param values [Array<Value, String>] An array of resolved {Value} objects. When resolving fails, use the friendly
    # ID instead.
    # @param uniqueness_context [ModelIndex] The uniqueness context for the attribute.
    def initialize(id:, name:, description:, friendly_id:, handle:, values:, uniqueness_context: nil)
      @id = id
      @name = name
      @description = description
      @friendly_id = friendly_id
      @handle = handle
      @values = values
      @uniqueness_context = uniqueness_context
    end

    private

    def values_valid?
      values&.each do |value|
        errors.add(
          :values,
          :not_found,
          message: "could not be resolved for friendly ID \"#{value}\"",
        ) unless value.is_a?(Value)
      end
    end
  end
end
