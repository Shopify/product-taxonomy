# frozen_string_literal: true

class LocalizationsValidator
  LOCALIZATION_DIRECTORY = "data/localizations"
  CATEGORY_DIRECTORY = "data/categories"
  ATTRIUBTES_DIRECTORY = "data/attributes.yml"
  VALUES_DIRECTORY = "data/values.yml"

  def call
    validate_categories
    validate_attributes
    validate_values
    validate_localization_loales
  end

  private

  def validate_categories
    Dir.glob("#{LOCALIZATION_DIRECTORY}/categories/*.yml").each do |file|
      language = File.basename(file, ".yml")
      localizations = YAML.load_file(file)
      Dir.glob("#{CATEGORY_DIRECTORY}/*.yml").each do |file|
        vertical = File.basename(file, ".yml")
        categories = YAML.load_file(file)

        missing_localization_keys = categories.reject do |category|
          localizations[language]["categories"][category["id"]]
        end
        error_message = "Missing localization keys for #{missing_localization_keys.map { _1["id"] }}"
        raise error_message unless missing_localization_keys.empty?

        missing_localizations = categories.reject do |category|
          localizations.dig(language, "categories", category["id"], "name")
        end

        error_message = "Missing localization names for #{missing_localizations.map { _1["id"] }}"
        raise error_message unless missing_localizations.empty?
      end
    end
  end

  def validate_attributes
    Dir.glob("#{LOCALIZATION_DIRECTORY}/attributes/*.yml").each do |file|
      language = File.basename(file, ".yml")
      localizations = YAML.load_file(file)
      attributes = YAML.load_file(ATTRIUBTES_DIRECTORY).values.flatten

      missing_localization_keys = attributes.reject do |attribute|
        localizations[language]["attributes"][attribute["friendly_id"]]
      end
      error_message = "Missing localization keys for #{missing_localization_keys.map { _1["friendly_id"] }}"
      raise error_message unless missing_localization_keys.empty?

      missing_localizations = attributes.reject do |attribute|
        localizations.dig(language, "attributes", attribute["friendly_id"], "name")
      end
      error_message = "Missing localization names for #{missing_localizations.map { _1["friendly_id"] }}"
      raise error_message unless missing_localizations.empty?
    end
  end

  def validate_values
    Dir.glob("#{LOCALIZATION_DIRECTORY}/values/*.yml").each do |file|
      language = File.basename(file, ".yml")
      localizations = YAML.load_file(file)
      values = YAML.load_file(VALUES_DIRECTORY)

      missing_localization_keys = values.reject do |value|
        localizations[language]["values"][value["friendly_id"]]
      end
      error_message = "Missing localization keys for #{missing_localization_keys.map { _1["friendly_id"] }}"
      raise error_message unless missing_localization_keys.empty?

      missing_localizations = values.reject do |value|
        localizations.dig(language, "values", value["friendly_id"], "name")
      end
      error_message = "Missing localization names for #{missing_localizations.map { _1["friendly_id"] }}"
      raise error_message unless missing_localizations.empty?
    end
  end

  def validate_localization_loales
    categories_locales = Dir.glob("#{LOCALIZATION_DIRECTORY}/categories/*.yml").map { File.basename(_1, ".yml") }
    attributes_locales = Dir.glob("#{LOCALIZATION_DIRECTORY}/attributes/*.yml").map { File.basename(_1, ".yml") }
    values_locales = Dir.glob("#{LOCALIZATION_DIRECTORY}/values/*.yml").map { File.basename(_1, ".yml") }

    error_message = "Not all locales have the same set of localizations"
    raise error_message unless categories_locales == attributes_locales && attributes_locales == values_locales
  end
end
