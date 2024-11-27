# frozen_string_literal: true

module ProductTaxonomy
  class ExtendedAttribute < Attribute
    class << self
      def localizations
        superclass.localizations # Extended attribute localizations are defined in the same place as attributes
      end
    end

    validate :values_from_valid?

    attr_reader :values_from

    # @param name [String] The name of the attribute.
    # @param handle [String] The handle of the attribute.
    # @param description [String] The description of the attribute.
    # @param friendly_id [String] The friendly ID of the attribute.
    # @param values_from [Attribute, String] A resolved {Attribute} object. When resolving fails, pass the friendly ID
    #   instead.
    def initialize(name:, handle:, description:, friendly_id:, values_from:)
      @values_from = values_from
      values_from.add_extended_attribute(self) if values_from.is_a?(Attribute)
      super(
        id: nil,
        name:,
        handle:,
        description:,
        friendly_id:,
        values: values_from.is_a?(Attribute) ? values_from.values : nil,
      )
    end

    private

    def values_from_valid?
      errors.add(
        :values_from,
        :not_found,
        message: "could not be resolved for friendly ID \"#{values_from}\"",
      ) unless values_from.is_a?(Attribute)
    end
  end
end
