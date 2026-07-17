# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class ExtendedAttributeTest < TestCase
    test "inherits closed-list metadata from base attribute" do
      value = Value.new(
        id: 1,
        name: "Black",
        friendly_id: "color__black",
        handle: "color__black",
      )
      attribute = Attribute.new(
        id: 1,
        name: "Color",
        description: "Defines the primary color or pattern, such as blue or striped",
        friendly_id: "color",
        handle: "color",
        values: [value],
      )
      extended_attribute = ExtendedAttribute.new(
        name: "Clothing Color",
        description: "Color of the clothing",
        friendly_id: "clothing_color",
        handle: "clothing_color",
        values_from: attribute,
      )

      assert_equal "closed_list", extended_attribute.type
      assert extended_attribute.closed_list?
      refute extended_attribute.measurement?
      assert_nil extended_attribute.measurement_type
      assert_nil extended_attribute.supported_units
      assert_equal [value], extended_attribute.values
    end

    test "inherits measurement metadata from base attribute" do
      attribute = Attribute.new(
        id: 12429,
        name: "Height",
        description: "Specifies the vertical measurement from bottom to top.",
        friendly_id: "height",
        handle: "height",
        type: "measurement",
        measurement_type: "dimension",
        supported_units: ["cm", "in"],
      )
      extended_attribute = ExtendedAttribute.new(
        name: "Interior Height",
        description: "Specifies the interior vertical measurement from bottom to top.",
        friendly_id: "interior_height",
        handle: "interior_height",
        values_from: attribute,
      )

      assert_equal "measurement", extended_attribute.type
      assert extended_attribute.measurement?
      refute extended_attribute.closed_list?
      assert_equal "dimension", extended_attribute.measurement_type
      assert_equal ["cm", "in"], extended_attribute.supported_units
      assert_empty extended_attribute.values
    end

    test "validates values_from is an attribute" do
      extended_attribute = ExtendedAttribute.new(
        name: "Clothing Color",
        description: "Color of the clothing",
        friendly_id: "clothing_color",
        handle: "clothing_color",
        values_from: "not an attribute",
      )

      error = assert_raises(ActiveModel::ValidationError) do
        extended_attribute.validate!(:create)
      end
      expected_errors = {
        base_attribute: [{ error: :not_found }],
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
        .with(File.join(ProductTaxonomy.data_path, "localizations", "attributes", "*.yml"))
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
