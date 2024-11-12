# frozen_string_literal: true

module ProductTaxonomy
  # High-performance in-memory container for a collection of models that uses Hash and Set to support fast uniqueness
  # checks and lookups by field value.
  class ModelIndex
    # Validator that checks for uniqueness of a field value across all models in a given ModelIndex. Requires the
    # `uniqueness_context` attribute to be set on the model as a reference to the ModelIndex.
    class UniquenessValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        context = record.uniqueness_context
        return if context.blank?

        if context.exists?(attribute => value)
          record.errors.add(attribute, "\"#{value}\" has already been used")
        end
      end
    end

    # @param model_class [Class] The class of models to index. Used to determine the fields on which to support
    #   uniqueness checks.
    # @param hashed_by [Array<String>] The fields by which to hash the models for fast lookups by field value.
    def initialize(model_class, hashed_by: [])
      @models = []
      @hashed_models = Array(hashed_by).each_with_object({}) { |field, hash| hash[field] = {} }
      @unique_fields = unique_fields(model_class)
      @unique_fields_seen = @unique_fields.each_with_object({}) { |field, hash| hash[field] = Set.new }
    end

    # Add a model to the index.
    #
    # @param model [Object] The model to add to the index.
    def add(model)
      @models << model
      @hashed_models.keys.each do |field|
        @hashed_models[field][model.send(field)] = model
      end
      @unique_fields.each do |field|
        @unique_fields_seen[field] << model.send(field)
      end
    end

    # Check if a field value exists across all models in the index.
    #
    # @param field_value_pair [Hash<Symbol, Object>] A hash with a single key-value pair for the field and value to
    #   check for existence.
    # @return [Boolean] Whether the value exists.
    def exists?(field_value_pair)
      field, value = field_value_pair.first
      raise ArgumentError, "Field not indexed for uniqueness: #{field}" unless @unique_fields.include?(field)

      @unique_fields_seen[field].include?(value)
    end

    # Get the hash of models indexed by a given field. Only works for fields that were specified as hashed fields when
    # the ModelIndex was created.
    #
    # @param field [Symbol] The field to get the hash for.
    # @return [Hash] The hash of models indexed by the field.
    def hashed_by(field)
      raise ArgumentError, "Field not hashed: #{field}" unless @hashed_models.key?(field)

      @hashed_models[field]
    end

    # Get the number of models in the index.
    #
    # @return [Integer] The number of models in the index.
    def size
      @models.size
    end

    private

    def unique_fields(model_class)
      model_class._validators.select do |_, validators|
        validators.any? do |validator|
          validator.is_a?(UniquenessValidator)
        end
      end.keys
    end
  end
end
