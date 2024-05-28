# frozen_string_literal: true

require_relative "../test_helper"

class LocalizationsTest < ActiveSupport::TestCase
  LOCALIZATION_DIRECTORY = "data/localizations"
  CATEGORY_DIRECTORY = "data/categories"
  ATTRIUBTES_DIRECTORY = "data/attributes.yml"
  VALUES_DIRECTORY = "data/values.yml"

  Dir.glob("#{LOCALIZATION_DIRECTORY}/categories/*.yml").each do |file|
    language = File.basename(file, ".yml")
    localizations = YAML.load_file(file)
    Dir.glob("#{CATEGORY_DIRECTORY}/*.yml").each do |file|
      vertical = File.basename(file, ".yml")
      categories = YAML.load_file(file)

      test "#{vertical} has localization keys in #{language} for every category" do
        missing_localization_keys = categories.reject do |category|
          localizations[language]["categories"][category["id"]]
        end
        error_message = "Missing localization keys for #{missing_localization_keys.map { _1["id"] }}"
        assert missing_localization_keys.empty?, error_message
      end

      test "#{vertical} has localization values in #{language} for every category" do
        missing_localizations = categories.reject do |category|
          localizations.dig(language, "categories", category["id"], "name")
        end

        error_message = "Missing localization names for #{missing_localizations.map { _1["id"] }}"
        assert missing_localizations.empty?, error_message
      end
    end
  end

  Dir.glob("#{LOCALIZATION_DIRECTORY}/attributes/*.yml").each do |file|
    language = File.basename(file, ".yml")
    localizations = YAML.load_file(file)
    attributes = YAML.load_file(ATTRIUBTES_DIRECTORY).values.flatten

    test "attributes have localization keys in #{language}" do
      missing_localization_keys = attributes.reject do |attribute|
        localizations[language]["attributes"][attribute["friendly_id"]]
      end
      error_message = "Missing localization keys for #{missing_localization_keys.map { _1["friendly_id"] }}"
      assert missing_localization_keys.empty?, error_message
    end

    test "attributes have localization values for name in #{language}" do
      missing_localizations = attributes.reject do |attribute|
        localizations.dig(language, "attributes", attribute["friendly_id"], "name")
      end
      error_message = "Missing localization names for #{missing_localizations.map { _1["friendly_id"] }}"
      assert missing_localizations.empty?, error_message
    end
  end

  Dir.glob("#{LOCALIZATION_DIRECTORY}/values/*.yml").each do |file|
    language = File.basename(file, ".yml")
    localizations = YAML.load_file(file)
    values = YAML.load_file(VALUES_DIRECTORY)

    test "values have localization keys in #{language}" do
      missing_localization_keys = values.reject do |value|
        localizations[language]["values"][value["friendly_id"]]
      end
      error_message = "Missing localization keys for #{missing_localization_keys.map { _1["friendly_id"] }}"
      assert missing_localization_keys.empty?, error_message
    end

    test "values have localizations for name in #{language}" do
      missing_localizations = values.reject do |value|
        localizations.dig(language, "values", value["friendly_id"], "name")
      end
      error_message = "Missing localization names for #{missing_localizations.map { _1["friendly_id"] }}"
      assert missing_localizations.empty?, error_message
    end
  end

  test "all resources have the same locales" do
    categories_locales = Dir.glob("#{LOCALIZATION_DIRECTORY}/categories/*.yml").map { File.basename(_1, ".yml") }
    attributes_locales = Dir.glob("#{LOCALIZATION_DIRECTORY}/attributes/*.yml").map { File.basename(_1, ".yml") }
    values_locales = Dir.glob("#{LOCALIZATION_DIRECTORY}/values/*.yml").map { File.basename(_1, ".yml") }

    all_locales = (categories_locales + attributes_locales + values_locales).uniq
    assert_equal all_locales, categories_locales
    assert_equal all_locales, attributes_locales
    assert_equal all_locales, values_locales
  end
end
