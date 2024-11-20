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
  end
end
