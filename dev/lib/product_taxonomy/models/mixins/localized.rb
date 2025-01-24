# frozen_string_literal: true

module ProductTaxonomy
  module Localized
    def localizations
      return @localizations if @localizations

      humanized_name = name.split("::").last.humanize.downcase.pluralize
      localization_path = File.join(ProductTaxonomy.data_path, "localizations", humanized_name, "*.yml")
      @localizations = Dir.glob(localization_path).each_with_object({}) do |file, localizations|
        locale = File.basename(file, ".yml")
        localizations[locale] = YAML.safe_load_file(file).dig(locale, humanized_name)
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
  end
end
