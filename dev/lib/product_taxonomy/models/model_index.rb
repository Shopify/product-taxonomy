# frozen_string_literal: true

module ProductTaxonomy
  # High-performance in-memory container for a collection of models that uses hashes to support fast uniqueness
  # checks and lookups by field value.
  class ModelIndex
    # Validator that checks for uniqueness of a field value across all models in a given ModelIndex. Requires the
    # `uniqueness_context` attribute to be set on the model as a reference to the ModelIndex.
    class UniquenessValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        context = record.uniqueness_context
        return if context.blank?

        if context.duplicate?(model: record, field: attribute)
          record.errors.add(attribute, :taken, message: "\"#{value}\" has already been used")
        end
      end
    end

    # @param model_class [Class] The class of models to index. Used to determine the fields on which to support
    #   uniqueness checks.
    def initialize(model_class)
      @unique_fields = unique_fields(model_class)
      @hashed_models = @unique_fields.each_with_object({}) { |field, hash| hash[field] = {} }
    end

    # Add a model to the index.
    #
    # @param model [Object] The model to add to the index.
    def add(model)
      @hashed_models.keys.each do |field|
        @hashed_models[field][model.send(field)] ||= model
      end
    end

    # Check if a field value is a duplicate of an existing model. A model is considered to be a duplicate if it was
    # added after the first model with that value.
    #
    # @param model [Object] The model to check for uniqueness.
    # @param field [Symbol] The field to check for uniqueness.
    # @return [Boolean] Whether the value is unique.
    def duplicate?(model:, field:)
      raise ArgumentError, "Field not hashed: #{field}" unless @hashed_models.key?(field)

      existing_model = @hashed_models[field][model.send(field)]
      return false if existing_model.nil?

      model != existing_model
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
      @hashed_models.first[1].values.size
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
