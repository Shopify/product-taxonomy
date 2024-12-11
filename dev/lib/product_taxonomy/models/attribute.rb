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

      # Get the JSON representation of all attributes.
      #
      # @param version [String] The version of the taxonomy.
      # @param locale [String] The locale to use for localized attributes.
      # @return [Hash] The JSON representation of all attributes.
      def to_json(version:, locale: "en")
        {
          "version" => version,
          "attributes" => sorted_base_attributes.map { _1.to_json(locale:) },
        }
      end

      # Get the TXT representation of all attributes.
      #
      # @param version [String] The version of the taxonomy.
      # @param locale [String] The locale to use for localized attributes.
      # @param padding [Integer] The padding to use for the GID. Defaults to the length of the longest GID.
      # @return [String] The TXT representation of all attributes.
      def to_txt(version:, locale: "en", padding: longest_gid_length)
        header = <<~HEADER
          # Shopify Product Taxonomy - Attributes: #{version}
          # Format: {GID} : {Attribute name}
        HEADER
        [
          header,
          *sorted_base_attributes.map { _1.to_txt(padding:, locale:) },
        ].join("\n")
      end

      # Reset all class-level state
      def reset
        @localizations = nil
        @hashed_models = nil
      end

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

      def longest_gid_length
        all.filter_map { _1.extended? ? nil : _1.gid.length }.max
      end

      def sorted_base_attributes
        all.reject(&:extended?).sort_by(&:name)
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

    #
    # Serialization
    #

    def to_json(locale: "en")
      {
        "id" => gid,
        "name" => name(locale:),
        "handle" => handle,
        "description" => description(locale:),
        "extended_attributes" => extended_attributes.sort_by(&:name).map do
          {
            "name" => _1.name(locale:),
            "handle" => _1.handle,
          }
        end,
        "values" => sorted_values(locale:).map do
          {
            "id" => _1.gid,
            "name" => _1.name(locale:),
            "handle" => _1.handle,
          }
        end,
      }
    end

    def to_txt(padding: 0, locale: "en")
      "#{gid.ljust(padding)} : #{name(locale:)}"
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
