# frozen_string_literal: true

module ProductTaxonomy
  class Attribute
    include ActiveModel::Validations
    extend Localized
    extend Indexed

    class << self
      # Load attributes from source data. By default, this data is deserialized from a YAML file in the `data` directory.
      #
      # @param source_data [Array<Hash>] The source data to load attributes from.
      def load_from_source(source_data)
        raise ArgumentError, "source_data must be a hash" unless source_data.is_a?(Hash)
        raise ArgumentError, "source_data must contain keys \"base_attributes\" and \"extended_attributes\"" unless
          source_data.keys.sort == ["base_attributes", "extended_attributes"]

        source_data.each do |type, attributes|
          attributes.each do |attribute_data|
            raise ArgumentError, "source_data must contain hashes" unless attribute_data.is_a?(Hash)

            attribute = case type
            when "base_attributes" then attribute_from(attribute_data)
            when "extended_attributes" then extended_attribute_from(attribute_data)
            end
            Attribute.add(attribute)
            attribute.validate!
          end
        end
      end

      # Reset all class-level state
      def reset
        @localizations = nil
        @hashed_models = nil
      end

      # Get base attributes only, sorted by name.
      #
      # @return [Array<Attribute>] The sorted base attributes.
      def sorted_base_attributes
        all.reject(&:extended?).sort_by(&:name)
      end

      # Get the next ID for a newly created attribute.
      #
      # @return [Integer] The next ID.
      def next_id = (all.max_by(&:id)&.id || 0) + 1

      private

      def attribute_from(attribute_data)
        values_by_friendly_id = attribute_data["values"]&.map { Value.find_by(friendly_id: _1) || _1 }
        Attribute.new(
          id: attribute_data["id"],
          name: attribute_data["name"],
          description: attribute_data["description"],
          friendly_id: attribute_data["friendly_id"],
          handle: attribute_data["handle"],
          values: values_by_friendly_id,
          is_manually_sorted: attribute_data["sorting"] == "custom",
        )
      end

      def extended_attribute_from(attribute_data)
        value_friendly_id = attribute_data["values_from"]
        ExtendedAttribute.new(
          name: attribute_data["name"],
          handle: attribute_data["handle"],
          description: attribute_data["description"],
          friendly_id: attribute_data["friendly_id"],
          values_from: Attribute.find_by(friendly_id: value_friendly_id) || value_friendly_id,
        )
      end
    end

    validates :id, presence: true, numericality: { only_integer: true }, if: -> { self.class == Attribute }
    validates :name, presence: true
    validates :friendly_id, presence: true
    validates :handle, presence: true
    validates :description, presence: true
    validates :values, presence: true, if: -> { self.class == Attribute }
    validates_with ProductTaxonomy::Indexed::UniquenessValidator, attributes: [:friendly_id]
    validate :values_valid?

    localized_attr_reader :name, :description

    attr_reader :id, :friendly_id, :handle, :values, :extended_attributes

    # @param id [Integer] The ID of the attribute.
    # @param name [String] The name of the attribute.
    # @param description [String] The description of the attribute.
    # @param friendly_id [String] The friendly ID of the attribute.
    # @param handle [String] The handle of the attribute.
    # @param values [Array<Value, String>] An array of resolved {Value} objects. When resolving fails, use the friendly
    # ID instead.
    def initialize(id:, name:, description:, friendly_id:, handle:, values:, is_manually_sorted: false)
      @id = id
      @name = name
      @description = description
      @friendly_id = friendly_id
      @handle = handle
      @values = values
      @extended_attributes = []
      @is_manually_sorted = is_manually_sorted
    end

    # Add an extended attribute to the attribute.
    #
    # @param extended_attribute [ExtendedAttribute] The extended attribute to add.
    def add_extended_attribute(extended_attribute)
      @extended_attributes << extended_attribute
    end

    # Add a value to the attribute.
    #
    # @param value [Value] The value to add.
    def add_value(value)
      @values << value
    end

    # The global ID of the attribute
    #
    # @return [String]
    def gid
      "gid://shopify/TaxonomyAttribute/#{id}"
    end

    # Whether the attribute is an extended attribute.
    #
    # @return [Boolean]
    def extended?
      is_a?(ExtendedAttribute)
    end

    # Whether the attribute is manually sorted.
    #
    # @return [Boolean]
    def manually_sorted?
      @is_manually_sorted
    end

    # Get the sorted values of the attribute.
    #
    # @param locale [String] The locale to sort by.
    # @return [Array<Value>] The sorted values.
    def sorted_values(locale: "en")
      if manually_sorted?
        values
      else
        Value.sort_by_localized_name(values, locale:)
      end
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
