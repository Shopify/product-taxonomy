# frozen_string_literal: true

module ProductTaxonomy
  # Mixin providing indexing for a model, using hashes to support fast uniqueness checks and lookups by field value.
  module Indexed
    class << self
      # Keep track of which model class used "extend Indexed" so that the model can be subclassed while still storing
      # model objects in a shared index on the superclass.
      def extended(indexed_model_class)
        indexed_model_class.instance_variable_set(:@is_indexed, true)
      end
    end

    # Validator that checks for uniqueness of a field value across all models in a given index.
    class UniquenessValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        if record.class.duplicate?(model: record, field: attribute)
          record.errors.add(attribute, :taken, message: "\"#{value}\" has already been used")
        end
      end
    end

    # Add a model to the index.
    #
    # @param model [Object] The model to add to the index.
    def add(model)
      hashed_models.keys.each do |field|
        hashed_models[field][model.send(field)] ||= model
      end
    end

    # Convenience method to create a model, validate it, and add it to the index. If the model is not valid, raise an
    # error.
    #
    # @param args [Array] The arguments to pass to the model's constructor.
    # @return [Object] The created model.
    def create_validate_and_add!(...)
      model = new(...)
      model.validate!
      add(model)
      model
    end

    # Check if a field value is a duplicate of an existing model. A model is considered to be a duplicate if it was
    # added after the first model with that value.
    #
    # @param model [Object] The model to check for uniqueness.
    # @param field [Symbol] The field to check for uniqueness.
    # @return [Boolean] Whether the value is unique.
    def duplicate?(model:, field:)
      raise ArgumentError, "Field not hashed: #{field}" unless hashed_models.key?(field)

      existing_model = hashed_models[field][model.send(field)]
      return false if existing_model.nil?

      model != existing_model
    end

    # Find a model by field value. Returns the first matching record or nil. Only works for fields marked unique.
    #
    # @param conditions [Hash] Hash of field-value pairs to search by
    # @return [Object, nil] The matching model or nil if not found
    def find_by(**conditions)
      field, value = conditions.first
      raise ArgumentError, "Field not hashed: #{field}" unless hashed_models.key?(field)

      hashed_models[field][value]
    end

    # Get the hash of models indexed by a given field. Only works for fields marked unique.
    #
    # @param field [Symbol] The field to get the hash for.
    # @return [Hash] The hash of models indexed by the given field.
    def hashed_by(field)
      raise ArgumentError, "Field not hashed: #{field}" unless hashed_models.key?(field)

      hashed_models[field]
    end

    # Get all models in the index.
    #
    # @return [Array<Object>] All models in the index.
    def all
      hashed_models.first[1].values
    end

    # Get the number of models in the index.
    #
    # @return [Integer] The number of models in the index.
    def size
      all.size
    end

    # Get the hash of hash of models, indexed by fields marked unique.
    #
    # @return [Hash] The hash of hash of models indexed by the fields marked unique.
    def hashed_models
      # If we're a subclass of the model class that originally extended Indexed, use the parent class' hashed_models.
      return superclass.hashed_models unless @is_indexed

      @hashed_models ||= unique_fields.each_with_object({}) do |field, hash|
        hash[field] = {}
      end
    end

    private

    def unique_fields
      _validators.select do |_, validators|
        validators.any? do |validator|
          validator.is_a?(UniquenessValidator)
        end
      end.keys
    end
  end
end
