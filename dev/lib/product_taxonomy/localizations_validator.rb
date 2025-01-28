# frozen_string_literal: true

module ProductTaxonomy
  module LocalizationsValidator
    class << self
      # Validate that all localizations are present for the given locales. If no locales are provided, all locales
      # will be validated and the consistency of locales across models will be checked.
      #
      # @param locales [Array<String>, nil] The locales to validate. If nil, all locales will be validated.
      def validate!(locales = nil)
        Category.validate_localizations!(locales)
        Attribute.validate_localizations!(locales)
        Value.validate_localizations!(locales)

        validate_locales_are_consistent! if locales.nil?
      end

      private

      def validate_locales_are_consistent!
        categories_locales = Category.localizations.keys
        attributes_locales = Attribute.localizations.keys
        values_locales = Value.localizations.keys

        error_message = "Not all model localizations have the same set of locales"
        raise ArgumentError,
          error_message unless categories_locales == attributes_locales && attributes_locales == values_locales
      end
    end
  end
end
