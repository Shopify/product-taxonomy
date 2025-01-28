# frozen_string_literal: true

module ProductTaxonomy
  module Localized
    def localizations
      return @localizations if @localizations

      localization_path = File.expand_path(
        "localizations/#{localizations_humanized_model_name}/*.yml",
        ProductTaxonomy.data_path,
      )
      @localizations = Dir.glob(localization_path).each_with_object({}) do |file, localizations|
        locale = File.basename(file, ".yml")
        localizations[locale] = YAML.safe_load_file(file).dig(locale, localizations_humanized_model_name)
      end
    end

    # Validate that all localizations are present for the given locales. If no locales are provided, all locales
    # will be validated.
    #
    # @param locales [Array<String>, nil] The locales to validate. If nil, all locales will be validated.
    def validate_localizations!(locales = nil)
      model_keys = all.map { |model| model.send(@localizations_keyed_by).to_s }
      locales_to_validate = locales || localizations.keys
      locales_to_validate.each do |locale|
        missing_localization_keys = model_keys.reject { |key| localizations.dig(locale, key, "name") }
        next if missing_localization_keys.empty?

        raise ArgumentError, "Missing or incomplete localizations for the following keys in " \
          "localizations/#{localizations_humanized_model_name}/#{locale}.yml: #{missing_localization_keys.join(", ")}"
      end
    end

    private

    # Define methods that return localized attributes by fetching from localization YAML files. Values for the `en`
    # locale come directly from the model's attributes.
    #
    # For example, if the class localizes `name` and `description` attributes keyed by `friendly_id`:
    #
    #   localized_attr_reader :name, :description, keyed_by: :friendly_id
    #
    # This will generate the following methods:
    #
    #   name(locale: "en")
    #   description(locale: "en")
    def localized_attr_reader(*attrs, keyed_by: :friendly_id)
      if @localizations_keyed_by.present? && @localizations_keyed_by != keyed_by
        raise ArgumentError, "Cannot localize attributes with different keyed_by values"
      end

      @localizations_keyed_by = keyed_by
      attrs.each do |attr|
        define_method(attr) do |locale: "en"|
          raw_value = instance_variable_get("@#{attr}")

          if locale == "en"
            raw_value
          else
            self.class.localizations.dig(locale, send(keyed_by).to_s, attr.to_s) || raw_value
          end
        end
      end
    end

    def localizations_humanized_model_name
      name.demodulize.humanize.downcase.pluralize
    end
  end
end
