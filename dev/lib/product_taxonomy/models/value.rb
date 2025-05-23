# frozen_string_literal: true

module ProductTaxonomy
  # An attribute value in the product taxonomy. Referenced by a {ProductTaxonomy::Attribute}. For example, an
  # attribute called "Color" could have values "Red", "Blue", and "Green".
  class Value
    include ActiveModel::Validations
    include FormattedValidationErrors
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

          Value.create_validate_and_add!(
            id: value_data["id"],
            name: value_data["name"],
            friendly_id: value_data["friendly_id"],
            handle: value_data["handle"],
          )
        end
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

      # Sort values according to their English name, taking "other" into account.
      #
      # @param values [Array<Value>] The values to sort.
      # @return [Array<Value>] The sorted values.
      def all_values_sorted
        all.sort_by do |value|
          [
            value.name(locale: "en").downcase == "other" ? 1 : 0,
            value.name(locale: "en"),
            value.id,
          ]
        end
      end

      # Get the next ID for a newly created value.
      #
      # @return [Integer] The next ID.
      def next_id = (all.max_by(&:id)&.id || 0) + 1
    end

    # Validations that run when the value is created
    validates :id, presence: true, numericality: { only_integer: true }, on: :create
    validates :name, presence: true, on: :create
    validates :friendly_id, presence: true, on: :create
    validates :handle, presence: true, on: :create
    validates_with ProductTaxonomy::Indexed::UniquenessValidator, attributes: [:friendly_id, :handle, :id], on: :create

    # Validations that run when the taxonomy has been loaded
    validate :friendly_id_prefix_resolves_to_attribute?, on: :taxonomy_loaded
    validate :handle_prefix_matches_attribute?, on: :taxonomy_loaded

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
      @primary_attribute ||= Attribute.find_by(friendly_id: primary_attribute_friendly_id)
    end

    # Get the full name of the value, including the primary attribute.
    #
    # @param locale [String] The locale to get the name in.
    # @return [String] The full name of the value.
    def full_name(locale: "en")
      "#{name(locale:)} [#{primary_attribute.name(locale:)}]"
    end

    private

    def primary_attribute_friendly_id = friendly_id.split("__").first

    #
    # Validation
    #
    def friendly_id_prefix_resolves_to_attribute?
      return if primary_attribute

      errors.add(
        :friendly_id,
        :invalid_prefix,
        message: "prefix \"#{primary_attribute_friendly_id}\" does not match the friendly_id of any attribute",
      )
    end

    def handle_prefix_matches_attribute?
      return if primary_attribute.nil?

      handle_prefix = handle.split("__").first
      return if primary_attribute && primary_attribute.handle == handle_prefix

      errors.add(
        :handle,
        :invalid_prefix,
        message: "prefix \"#{handle_prefix}\" does not match primary attribute handle \"#{primary_attribute.handle}\"",
      )
    end
  end
end
