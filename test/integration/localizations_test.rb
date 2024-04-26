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
        assert missing_localization_keys.empty?, "Missing localizations for #{missing_localization_keys.map do |category|
                                                                                category["id"]
                                                                              end}"
      end

      test "#{vertical} has localization values in #{language} for every category" do
        skip "Some localizations are missing skipping until they are added"

        missing_localizations = categories.reject do |category|
          localizations.dig(language, "categories", category["id"], "name")
        end
        assert missing_localizations.empty?, "Missing localizations for #{missing_localizations.map do |category|
                                                                            category["id"]
                                                                          end}"
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
      skip "Some localizations are missing skipping until they are added"

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
      skip "Some localizations are missing skipping until they are added"

      missing_localizations = values.reject do |value|
        localizations.dig(language, "values", value["friendly_id"], "name")
      end
      error_message = "Missing localization names for #{missing_localizations.map { _1["friendly_id"] }}"
      assert missing_localizations.empty?, error_message
    end
  end
end
