# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class ExtendedAttributeTest < TestCase
    test "validates values_from is an attribute" do
      extended_attribute = ExtendedAttribute.new(
        name: "Clothing Color",
        description: "Color of the clothing",
        friendly_id: "clothing_color",
        handle: "clothing_color",
        values_from: "not an attribute",
      )

      error = assert_raises(ActiveModel::ValidationError) do
        extended_attribute.validate!
      end
      expected_errors = {
        values_from: [{ error: :not_found }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "localized attributes are returned correctly" do
      attribute = Attribute.new(
        id: 1,
        name: "Color",
        description: "Defines the primary color or pattern, such as blue or striped",
        friendly_id: "color",
        handle: "color",
        values: [],
      )
      extended_attribute = ExtendedAttribute.new(
        name: "Clothing Color",
        description: "Color of the clothing",
        friendly_id: "clothing_color",
        handle: "clothing_color",
        values_from: attribute,
      )
      fr_yaml = <<~YAML
        fr:
          attributes:
            clothing_color:
              name: "Nom en français"
              description: "Description en français"
      YAML
      es_yaml = <<~YAML
        es:
          attributes:
            clothing_color:
              name: "Nombre en español"
              description: "Descripción en español"
      YAML
      Dir.expects(:glob)
        .with(File.join(DATA_PATH, "localizations", "attributes", "*.yml"))
        .returns(["fake/path/fr.yml", "fake/path/es.yml"])
      YAML.expects(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
      YAML.expects(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

      assert_equal "Clothing Color", extended_attribute.name
      assert_equal "Color of the clothing", extended_attribute.description
      assert_equal "Clothing Color", extended_attribute.name(locale: "en")
      assert_equal "Color of the clothing", extended_attribute.description(locale: "en")
      assert_equal "Nom en français", extended_attribute.name(locale: "fr")
      assert_equal "Description en français", extended_attribute.description(locale: "fr")
      assert_equal "Nombre en español", extended_attribute.name(locale: "es")
      assert_equal "Descripción en español", extended_attribute.description(locale: "es")
      assert_equal "Clothing Color", extended_attribute.name(locale: "cs") # fall back to en
      assert_equal "Color of the clothing", extended_attribute.description(locale: "cs") # fall back to en
    end
  end
end
