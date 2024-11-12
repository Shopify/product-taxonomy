# frozen_string_literal: true

module ProductTaxonomy
  # An attribute value in the product taxonomy. Referenced by a {ProductTaxonomy::Attribute}. For example, an
  # attribute called "Color" could have values "Red", "Blue", and "Green".
  class Value
    include ActiveModel::Validations

    class << self
      # Load values from source data. By default, this data is deserialized from a YAML file in the `data` directory.
      #
      # @param source_data [Array<Hash>] The source data to load values from.
      # @return [Hash<String, Value>] A hash of values keyed by their friendly ID.
      def load_from_source(source_data:)
        model_index = ModelIndex.new(self, hashed_by: :friendly_id)

        raise ArgumentError, "source_data must be an array" unless source_data.is_a?(Array)

        source_data.each do |value_data|
          raise ArgumentError, "source_data must contain hashes" unless value_data.is_a?(Hash)

          value = Value.new(
            id: value_data["id"],
            name: value_data["name"],
            friendly_id: value_data["friendly_id"],
            handle: value_data["handle"],
            uniqueness_context: model_index,
          )
          value.validate!
          model_index.add(value)
        end

        model_index.hashed_by(:friendly_id)
      end
    end

    validates :id, presence: true, numericality: { only_integer: true }
    validates :name, presence: true
    validates :friendly_id, presence: true
    validates :handle, presence: true
    validates_with ProductTaxonomy::ModelIndex::UniquenessValidator, attributes: [:friendly_id, :handle, :id]

    attr_reader :id, :name, :friendly_id, :handle, :uniqueness_context

    def initialize(id:, name:, friendly_id:, handle:, uniqueness_context:)
      @id = id
      @name = name
      @friendly_id = friendly_id
      @handle = handle
      @uniqueness_context = uniqueness_context
    end
  end
end
