# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class AttributeTest < TestCase
    setup do
      @value = Value.new(
        id: 1,
        name: "Black",
        friendly_id: "color__black",
        handle: "color__black",
      )
      @attribute = Attribute.new(
        id: 1,
        name: "Color",
        description: "Defines the primary color or pattern, such as blue or striped",
        friendly_id: "color",
        handle: "color",
        values: [@value],
      )
      @extended_attribute = ExtendedAttribute.new(
        name: "Clothing Color",
        description: "Color of the clothing",
        friendly_id: "clothing_color",
        handle: "clothing_color",
        values_from: @attribute,
      )
    end

    test "load_from_source loads attributes from deserialized YAML" do
      attributes_yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          values:
          - color__black
        - id: 3
          name: Pattern
          description: Describes the design or motif of a product, such as floral or striped
          friendly_id: pattern
          handle: pattern
          values:
          - pattern__abstract
        extended_attributes:
        - id: 4
          name: Clothing Pattern
          description: Describes the design or motif of a product, such as floral or striped
          friendly_id: clothing_pattern
          handle: clothing_pattern
          values_from: pattern
      YAML
      values_yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
        - id: 2
          name: Abstract
          friendly_id: pattern__abstract
          handle: pattern__abstract
      YAML
      Value.load_from_source(YAML.safe_load(values_yaml_content))
      Attribute.load_from_source(YAML.safe_load(attributes_yaml_content))

      assert_equal 3, Attribute.size

      color = Attribute.find_by(friendly_id: "color")
      assert_instance_of Attribute, color
      assert_equal "color", color.handle
      refute color.manually_sorted?
      assert_instance_of Array, color.values
      assert_instance_of Value, color.values.first
      assert_equal ["color__black"], color.values.map(&:friendly_id)

      pattern = Attribute.find_by(friendly_id: "pattern")
      assert_instance_of Attribute, pattern
      assert_equal "pattern", pattern.handle
      refute pattern.manually_sorted?
      assert_instance_of Array, pattern.values
      assert_instance_of Value, pattern.values.first
      assert_equal ["pattern__abstract"], pattern.values.map(&:friendly_id)

      clothing_pattern = Attribute.find_by(friendly_id: "clothing_pattern")
      assert_instance_of ExtendedAttribute, clothing_pattern
      assert_equal "clothing_pattern", clothing_pattern.handle
      refute clothing_pattern.manually_sorted?
      assert_instance_of Array, clothing_pattern.values
      assert_instance_of Value, clothing_pattern.values.first
      assert_equal ["pattern__abstract"], clothing_pattern.values.map(&:friendly_id)
    end

    test "load_from_source raises an error if the source YAML does not follow the expected schema" do
      yaml_content = <<~YAML
        ---
        foo=bar
      YAML

      assert_raises(ArgumentError) { Attribute.load_from_source(YAML.safe_load(yaml_content)) }
    end

    test "load_from_source raises an error if the source data contains incomplete attributes" do
      yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
        extended_attributes: []
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        friendly_id: [{ error: :blank }],
        handle: [{ error: :blank }],
        description: [{ error: :blank }],
        values: [{ error: :blank }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises an error if the source data contains attributes with empty values" do
      yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          values: []
        extended_attributes: []
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        values: [{ error: :blank }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises an error if the source data contains attributes with values that are not found" do
      yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          values:
          - foo
        extended_attributes: []
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        values: [{ error: :not_found }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises an error if the source data contains incomplete extended attributes" do
      yaml_content = <<~YAML
        ---
        base_attributes: []
        extended_attributes:
        - id: 2
          name: Clothing Color
          description: Defines the primary color or pattern, such as blue or striped
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        friendly_id: [{ error: :blank }],
        handle: [{ error: :blank }],
        values_from: [{ error: :not_found }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises an error if the source data contains extended attributes with values_from that is not found" do
      yaml_content = <<~YAML
        ---
        base_attributes: []
        extended_attributes:
        - id: 2
          name: Clothing Color
          description: Defines the primary color or pattern, such as blue or striped
          handle: clothing_color
          friendly_id: clothing_color
          values_from: foo
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        values_from: [{ error: :not_found }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises an error if the source data contains duplicate friendly IDs" do
      attributes_yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          values:
          - color__black
        - id: 2
          name: Pattern
          description: Describes the design or motif of a product, such as floral or striped
          friendly_id: color
          handle: pattern
          values:
          - pattern__abstract
        extended_attributes: []
      YAML
      values_yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
        - id: 2
          name: Abstract
          friendly_id: pattern__abstract
          handle: pattern__abstract
      YAML
      Value.load_from_source(YAML.safe_load(values_yaml_content))

      error = assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(YAML.safe_load(attributes_yaml_content))
      end
      expected_errors = {
        friendly_id: [{ error: :taken }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises an error if the source data contains an invalid ID" do
      attributes_yaml_content = <<~YAML
        ---
        base_attributes:
        - id: foo
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          values:
          - color__black
        extended_attributes: []
      YAML
      values_yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
      YAML
      Value.load_from_source(YAML.safe_load(values_yaml_content))

      error = assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(YAML.safe_load(attributes_yaml_content))
      end
      expected_errors = {
        id: [{ error: :not_a_number, value: "foo" }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source correctly loads attribute with manually sorted values" do
      attributes_yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          sorting: custom
          values:
          - color__black
        extended_attributes: []
      YAML
      values_yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
      YAML
      Value.load_from_source(YAML.safe_load(values_yaml_content))

      Attribute.load_from_source(YAML.safe_load(attributes_yaml_content))
      assert Attribute.find_by(friendly_id: "color").manually_sorted?
    end

    test "localized attributes are returned correctly" do
      stub_localizations

      attribute = Attribute.new(
        id: 1,
        name: "Raw name",
        description: "Raw description",
        friendly_id: "color",
        handle: "color",
        values: [],
      )
      assert_equal "Raw name", attribute.name
      assert_equal "Raw description", attribute.description
      assert_equal "Raw name", attribute.name(locale: "en")
      assert_equal "Raw description", attribute.description(locale: "en")
      assert_equal "Nom en français", attribute.name(locale: "fr")
      assert_equal "Description en français", attribute.description(locale: "fr")
      assert_equal "Nombre en español", attribute.name(locale: "es")
      assert_equal "Descripción en español", attribute.description(locale: "es")
      assert_equal "Raw name", attribute.name(locale: "cs") # fall back to en
      assert_equal "Raw description", attribute.description(locale: "cs") # fall back to en
    end

    test "extended attributes are added to the base attribute specified in values_from" do
      assert_equal 1, @attribute.extended_attributes.size
      assert_equal @extended_attribute, @attribute.extended_attributes.first
    end

    test "gid returns the global ID" do
      assert_equal "gid://shopify/TaxonomyAttribute/1", @attribute.gid
    end

    test "extended? returns true if the attribute is extended" do
      assert @extended_attribute.extended?
    end

    test "extended? returns false if the attribute is not extended" do
      refute @attribute.extended?
    end

    test "to_json returns the JSON representation of the attribute" do
      expected_json = {
        "id" => "gid://shopify/TaxonomyAttribute/1",
        "name" => "Color",
        "handle" => "color",
        "description" => "Defines the primary color or pattern, such as blue or striped",
        "extended_attributes" => [
          {
            "name" => "Clothing Color",
            "handle" => "clothing_color",
          },
        ],
        "values" => [
          {
            "id" => "gid://shopify/TaxonomyValue/1",
            "name" => "Black",
            "handle" => "color__black",
          },
        ],
      }
      assert_equal expected_json, @attribute.to_json
    end

    test "to_json returns the localized JSON representation of the attribute" do
      stub_localizations

      expected_json = {
        "id" => "gid://shopify/TaxonomyAttribute/1",
        "name" => "Nom en français",
        "handle" => "color",
        "description" => "Description en français",
        "extended_attributes" => [
          {
            "name" => "Nom en français (extended)",
            "handle" => "clothing_color",
          },
        ],
        "values" => [
          {
            "id" => "gid://shopify/TaxonomyValue/1",
            "name" => "Black",
            "handle" => "color__black",
          },
        ],
      }
      assert_equal expected_json, @attribute.to_json(locale: "fr")
    end

    test "Attribute.to_json returns the JSON representation of all attributes" do
      Attribute.add(@attribute)
      expected_json = {
        "version" => "1.0",
        "attributes" => [{
          "id" => "gid://shopify/TaxonomyAttribute/1",
          "name" => "Color",
          "handle" => "color",
          "description" => "Defines the primary color or pattern, such as blue or striped",
          "extended_attributes" => [
            {
              "name" => "Clothing Color",
              "handle" => "clothing_color",
            },
          ],
          "values" => [
            {
              "id" => "gid://shopify/TaxonomyValue/1",
              "name" => "Black",
              "handle" => "color__black",
            },
          ],
        }],
      }
      assert_equal expected_json, Attribute.to_json(version: "1.0")
    end

    test "Attribute.to_json returns the JSON representation of all attributes sorted by name" do
      add_attributes_for_sorting

      expected_json = {
        "version" => "1.0",
        "attributes" => [
          {
            "id" => "gid://shopify/TaxonomyAttribute/3",
            "name" => "Aaaa",
            "handle" => "aaaa",
            "description" => "Aaaa",
            "extended_attributes" => [],
            "values" => [],
          },
          {
            "id" => "gid://shopify/TaxonomyAttribute/2",
            "name" => "Bbbb",
            "handle" => "bbbb",
            "description" => "Bbbb",
            "extended_attributes" => [],
            "values" => [],
          },
          {
            "id" => "gid://shopify/TaxonomyAttribute/1",
            "name" => "Cccc",
            "handle" => "cccc",
            "description" => "Cccc",
            "extended_attributes" => [],
            "values" => [],
          },
        ],
      }
      assert_equal expected_json, Attribute.to_json(version: "1.0")
    end

    test "to_txt returns the TXT representation of the attribute" do
      assert_equal "gid://shopify/TaxonomyAttribute/1 : Color", @attribute.to_txt
    end

    test "to_txt returns the localized TXT representation of the attribute" do
      stub_localizations

      assert_equal "gid://shopify/TaxonomyAttribute/1 : Nom en français", @attribute.to_txt(locale: "fr")
    end

    test "Attribute.to_txt returns the TXT representation of all attributes with correct padding" do
      attribute2 = Attribute.new(
        id: 123456,
        name: "Pattern",
        description: "Describes the design or motif of a product, such as floral or striped",
        friendly_id: "pattern",
        handle: "pattern",
        values: [],
      )
      Attribute.add(@attribute)
      Attribute.add(attribute2)

      expected_txt = <<~TXT
        # Shopify Product Taxonomy - Attributes: 1.0
        # Format: {GID} : {Attribute name}

        gid://shopify/TaxonomyAttribute/1      : Color
        gid://shopify/TaxonomyAttribute/123456 : Pattern
      TXT
      assert_equal expected_txt.strip, Attribute.to_txt(version: "1.0")
    end

    test "Attribute.to_txt returns the TXT representation of all attributes sorted by name" do
      add_attributes_for_sorting

      expected_txt = <<~TXT
        # Shopify Product Taxonomy - Attributes: 1.0
        # Format: {GID} : {Attribute name}

        gid://shopify/TaxonomyAttribute/3 : Aaaa
        gid://shopify/TaxonomyAttribute/2 : Bbbb
        gid://shopify/TaxonomyAttribute/1 : Cccc
      TXT
      assert_equal expected_txt.strip, Attribute.to_txt(version: "1.0")
    end

    test "to_json calls Value.sort_by_localized_name when sorting is not custom" do
      attribute = Attribute.new(
        id: 1,
        name: "Color",
        description: "Defines the primary color or pattern, such as blue or striped",
        friendly_id: "color",
        handle: "color",
        values: [@value],
        is_manually_sorted: false,
      )
      Value.expects(:sort_by_localized_name)
        .with(attribute.values, locale: "en")
        .returns([@value])
      attribute.to_json
    end

    test "to_json does not call Value.sort_by_localized_name when sorting is custom" do
      attribute = Attribute.new(
        id: 1,
        name: "Color",
        description: "Defines the primary color or pattern, such as blue or striped",
        friendly_id: "color",
        handle: "color",
        values: [@value],
        is_manually_sorted: true,
      )
      Value.expects(:sort_by_localized_name).with(attribute.values, locale: "en").never
      attribute.to_json
    end

    test "to_json returns extended attributes sorted by name" do
      attr = Attribute.new(
        id: 1,
        name: "Color",
        description: "Defines the primary color or pattern, such as blue or striped",
        friendly_id: "color",
        handle: "color",
        values: [@value],
      )
      ExtendedAttribute.new(name: "Cccc", handle: "cccc", description: "Cccc", friendly_id: "cccc", values_from: attr)
      ExtendedAttribute.new(name: "Bbbb", handle: "bbbb", description: "Bbbb", friendly_id: "bbbb", values_from: attr)
      ExtendedAttribute.new(name: "Aaaa", handle: "aaaa", description: "Aaaa", friendly_id: "aaaa", values_from: attr)

      expected_json = {
        "id" => "gid://shopify/TaxonomyAttribute/1",
        "name" => "Color",
        "handle" => "color",
        "description" => "Defines the primary color or pattern, such as blue or striped",
        "extended_attributes" => [
          {
            "name" => "Aaaa",
            "handle" => "aaaa",
          },
          {
            "name" => "Bbbb",
            "handle" => "bbbb",
          },
          {
            "name" => "Cccc",
            "handle" => "cccc",
          },
        ],
        "values" => [
          {
            "id" => "gid://shopify/TaxonomyValue/1",
            "name" => "Black",
            "handle" => "color__black",
          },
        ],
      }
      assert_equal expected_json, attr.to_json
    end

    private

    def stub_localizations
      fr_yaml = <<~YAML
        fr:
          attributes:
            color:
              name: "Nom en français"
              description: "Description en français"
            clothing_color:
              name: "Nom en français (extended)"
              description: "Description en français (extended)"
      YAML
      es_yaml = <<~YAML
        es:
          attributes:
            color:
              name: "Nombre en español"
              description: "Descripción en español"
            clothing_color:
              name: "Nombre en español (extended)"
              description: "Descripción en español (extended)"
      YAML
      Dir.stubs(:glob)
        .with(File.join(DATA_PATH, "localizations", "attributes", "*.yml"))
        .returns(["fake/path/fr.yml", "fake/path/es.yml"])
      YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
      YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

      Dir.stubs(:glob)
        .with(File.join(DATA_PATH, "localizations", "values", "*.yml"))
        .returns([])
    end

    def add_attributes_for_sorting
      [
        Attribute.new(id: 1, name: "Cccc", description: "Cccc", friendly_id: "cccc", handle: "cccc", values: []),
        Attribute.new(id: 2, name: "Bbbb", description: "Bbbb", friendly_id: "bbbb", handle: "bbbb", values: []),
        Attribute.new(id: 3, name: "Aaaa", description: "Aaaa", friendly_id: "aaaa", handle: "aaaa", values: []),
      ].each { Attribute.add(_1) }
    end
  end
end
