# frozen_string_literal: true

module ProductTaxonomy
  class Attribute
    include ActiveModel::Validations
    extend Localized

    class << self
      # Load attributes from source data. By default, this data is deserialized from a YAML file in the `data` directory.
      #
      # @param source_data [Array<Hash>] The source data to load attributes from.
      # @param values [Hash<String, Value>] A hash of {Value} objects keyed by their friendly ID.
      # @return [ModelIndex<Attribute>] A model index of {Attribute} objects.
      def load_from_source(source_data:, values:)
        model_index = ModelIndex.new(self)
        raise ArgumentError, "source_data must be a hash" unless source_data.is_a?(Hash)
        raise ArgumentError, "source_data must contain keys \"base_attributes\" and \"extended_attributes\"" unless
          source_data.keys.sort == ["base_attributes", "extended_attributes"]

        source_data.each do |type, attributes|
          attributes.each do |attribute_data|
            raise ArgumentError, "source_data must contain hashes" unless attribute_data.is_a?(Hash)

            attribute = case type
            when "base_attributes" then attribute_from(attribute_data:, values:, model_index:)
            when "extended_attributes" then extended_attribute_from(attribute_data:, model_index:)
            end
            model_index.add(attribute)
            attribute.validate!
          end
        end

        model_index
      end

      private

      def attribute_from(attribute_data:, values:, model_index:)
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
      end

      def extended_attribute_from(attribute_data:, model_index:)
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
    end

    validates :id, presence: true, numericality: { only_integer: true }, if: -> { self.class == Attribute }
    validates :name, presence: true
    validates :friendly_id, presence: true
    validates :handle, presence: true
    validates :description, presence: true
    validates :values, presence: true, if: -> { self.class == Attribute }
    validates_with ProductTaxonomy::ModelIndex::UniquenessValidator, attributes: [:friendly_id]
    validate :values_valid?

    localized_attr_reader :name, :description

    attr_reader :id, :friendly_id, :handle, :values, :uniqueness_context

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
        next if value.is_a?(Value)

        errors.add(
          :values,
          :not_found,
          message: "could not be resolved for friendly ID \"#{value}\"",
        )
      end
    end
  end
end
