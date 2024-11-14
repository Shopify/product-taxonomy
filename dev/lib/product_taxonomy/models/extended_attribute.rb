# frozen_string_literal: true

module ProductTaxonomy
  class ExtendedAttribute < Attribute
    validate :values_from_valid?

    # @param name [String] The name of the attribute.
    # @param handle [String] The handle of the attribute.
    # @param description [String] The description of the attribute.
    # @param friendly_id [String] The friendly ID of the attribute.
    # @param values_from [Attribute, String] A resolved {Attribute} object. When resolving fails, pass the friendly ID
    #   instead.
    # @param uniqueness_context [ModelIndex] The uniqueness context for the attribute.
    def initialize(name:, handle:, description:, friendly_id:, values_from:, uniqueness_context: nil)
      @values_from = values_from
      super(
        id: nil,
        name:,
        handle:,
        description:,
        friendly_id:,
        values: values_from.is_a?(Attribute) ? values_from.values : nil,
        uniqueness_context:,
      )
    end

    private

    def values_from_valid?
      errors.add(
        :values_from,
        "Attribute with friendly ID \"#{@values_from}\" was not found",
      ) unless @values_from.is_a?(Attribute)
    end
  end
end
