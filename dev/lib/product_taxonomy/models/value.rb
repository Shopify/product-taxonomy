# frozen_string_literal: true

module ProductTaxonomy
  # An attribute value in the product taxonomy. Referenced by a {ProductTaxonomy::Attribute}. For example, an
  # attribute called "Color" could have values "Red", "Blue", and "Green".
  class Value
    include ActiveModel::Validations
    extend Localized
    extend Indexed

    class << self
      # Load values from source data. By default, this data is deserialized from a YAML file in the `data` directory.
      #
      # @param source_data [Array<Hash>] The source data to load values from.
      def load_from_source(source_data)
        raise ArgumentError, "source_data must be an array" unless source_data.is_a?(Array)

        source_data.each do |value_data|
          raise ArgumentError, "source_data must contain hashes" unless value_data.is_a?(Hash)

          value = Value.new(
            id: value_data["id"],
            name: value_data["name"],
            friendly_id: value_data["friendly_id"],
            handle: value_data["handle"],
          )
          Value.add(value)
          value.validate!
        end
      end

      # Get the JSON representation of all values.
      #
      # @param version [String] The version of the taxonomy.
      # @param locale [String] The locale to use for localized attributes.
      # @return [Hash] The JSON representation of all values.
      def to_json(version:, locale: "en")
        {
          "version" => version,
          "values" => all_values_sorted.map { _1.to_json(locale:) },
        }
      end

      # Get the TXT representation of all values.
      #
      # @param version [String] The version of the taxonomy.
      # @param locale [String] The locale to use for localized attributes.
      # @param padding [Integer] The padding to use for the GID. Defaults to the length of the longest GID.
      # @return [String] The TXT representation of all values.
      def to_txt(version:, locale: "en", padding: longest_gid_length)
        header = <<~HEADER
          # Shopify Product Taxonomy - Attribute Values: #{version}
          # Format: {GID} : {Value name} [{Attribute name}]
        HEADER
        [
          header,
          *all_values_sorted.map { _1.to_txt(padding:, locale:) },
        ].join("\n")
      end

      # Reset all class-level state
      def reset
        @localizations = nil
        @hashed_models = nil
      end

      # Sort values by their localized name.
      #
      # @param values [Array<Value>] The values to sort.
      # @param locale [String] The locale to sort by.
      # @return [Array<Value>] The sorted values.
      def sort_by_localized_name(values, locale: "en")
        values.sort_by.with_index do |value, idx|
          [
            value.name(locale: "en").downcase == "other" ? 1 : 0,
            *AlphanumericSorter.normalize_value(value.name(locale:)),
            idx,
          ]
        end
      end

      private

      def longest_gid_length
        largest_id = hashed_by(:id).keys.max
        find_by(id: largest_id).gid.length
      end

      def all_values_sorted
        all.sort_by do |value|
          [
            value.name(locale: "en").downcase == "other" ? 1 : 0,
            value.name(locale: "en"),
            value.id,
          ]
        end
      end
    end

    validates :id, presence: true, numericality: { only_integer: true }
    validates :name, presence: true
    validates :friendly_id, presence: true
    validates :handle, presence: true
    validates_with ProductTaxonomy::Indexed::UniquenessValidator, attributes: [:friendly_id, :handle, :id]

    localized_attr_reader :name

    attr_reader :id, :friendly_id, :handle

    # @param id [Integer] The ID of the value.
    # @param name [String] The name of the value.
    # @param friendly_id [String] The friendly ID of the value.
    # @param handle [String] The handle of the value.
    def initialize(id:, name:, friendly_id:, handle:)
      @id = id
      @name = name
      @friendly_id = friendly_id
      @handle = handle
    end

    def gid
      "gid://shopify/TaxonomyValue/#{id}"
    end

    # Get the primary attribute for this value.
    #
    # @return [ProductTaxonomy::Attribute] The primary attribute for this value.
    def primary_attribute
      @primary_attribute ||= Attribute.find_by(friendly_id: friendly_id.split("__").first)
    end

    # Get the full name of the value, including the primary attribute.
    #
    # @param locale [String] The locale to get the name in.
    # @return [String] The full name of the value.
    def full_name(locale: "en")
      "#{name(locale:)} [#{primary_attribute.name(locale:)}]"
    end

    #
    # Serialization
    #
    def to_json(locale: "en")
      {
        "id" => gid,
        "name" => name(locale:),
        "handle" => handle,
      }
    end

    def to_txt(padding: 0, locale: "en")
      "#{gid.ljust(padding)} : #{full_name(locale:)}"
    end
  end
end
