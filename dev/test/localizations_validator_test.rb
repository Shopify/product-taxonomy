# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class LocalizationsValidatorTest < TestCase
    setup do
      @category = Category.new(id: "test-1", name: "Test Category")
      @attribute = Attribute.new(
        id: 1,
        name: "Test Attribute",
        friendly_id: "test_attr",
        handle: "test_attr",
        description: "Test description",
        values: [],
      )
      @value = Value.new(
        id: 1,
        name: "Test Value",
        friendly_id: "test_value",
        handle: "test_value",
      )

      Category.stubs(:all).returns([@category])
      Attribute.stubs(:all).returns([@attribute])
      Value.stubs(:all).returns([@value])

      @fr_categories_yaml = <<~YAML
        fr:
          categories:
            "test-1":
              name: "Catégorie de test"
      YAML

      @fr_attributes_yaml = <<~YAML
        fr:
          attributes:
            "test_attr":
              name: "Attribut de test"
              description: "Description de test"
      YAML

      @fr_values_yaml = <<~YAML
        fr:
          values:
            "test_value":
              name: "Valeur de test"
      YAML

      @es_categories_yaml = <<~YAML
        es:
          categories:
            "test-1":
              name: "Categoría de prueba"
      YAML

      @es_attributes_yaml = <<~YAML
        es:
          attributes:
            "test_attr":
              name: "Atributo de prueba"
              description: "Descripción de prueba"
      YAML

      @es_values_yaml = <<~YAML
        es:
          values:
            "test_value":
              name: "Valor de prueba"
      YAML

      ProductTaxonomy.stubs(:data_path).returns("/fake/path")

      Dir.stubs(:glob)
        .with("/fake/path/localizations/categories/*.yml")
        .returns(["/fake/path/localizations/categories/fr.yml", "/fake/path/localizations/categories/es.yml"])
      Dir.stubs(:glob)
        .with("/fake/path/localizations/attributes/*.yml")
        .returns(["/fake/path/localizations/attributes/fr.yml", "/fake/path/localizations/attributes/es.yml"])
      Dir.stubs(:glob)
        .with("/fake/path/localizations/values/*.yml")
        .returns(["/fake/path/localizations/values/fr.yml", "/fake/path/localizations/values/es.yml"])

      YAML.stubs(:safe_load_file)
        .with("/fake/path/localizations/categories/fr.yml")
        .returns(YAML.safe_load(@fr_categories_yaml))
      YAML.stubs(:safe_load_file)
        .with("/fake/path/localizations/categories/es.yml")
        .returns(YAML.safe_load(@es_categories_yaml))
      YAML.stubs(:safe_load_file)
        .with("/fake/path/localizations/attributes/fr.yml")
        .returns(YAML.safe_load(@fr_attributes_yaml))
      YAML.stubs(:safe_load_file)
        .with("/fake/path/localizations/attributes/es.yml")
        .returns(YAML.safe_load(@es_attributes_yaml))
      YAML.stubs(:safe_load_file)
        .with("/fake/path/localizations/values/fr.yml")
        .returns(YAML.safe_load(@fr_values_yaml))
      YAML.stubs(:safe_load_file)
        .with("/fake/path/localizations/values/es.yml")
        .returns(YAML.safe_load(@es_values_yaml))
    end

    teardown do
      Category.instance_variable_set(:@localizations, nil)
      Attribute.instance_variable_set(:@localizations, nil)
      Value.instance_variable_set(:@localizations, nil)
    end

    test "validate! passes when all required localizations are present" do
      assert_nothing_raised do
        LocalizationsValidator.validate!
        LocalizationsValidator.validate!(["fr"])
        LocalizationsValidator.validate!(["es"])
        LocalizationsValidator.validate!(["fr", "es"])
      end
    end

    test "validate! raises error when category localizations are missing" do
      category2 = Category.new(id: "test-2", name: "Second Category")
      Category.stubs(:all).returns([@category, category2])

      assert_raises(ArgumentError) do
        LocalizationsValidator.validate!(["fr"])
      end
    end

    test "validate! raises error when attribute localizations are missing" do
      attribute2 = Attribute.new(
        id: 2,
        name: "Second Attribute",
        friendly_id: "test_attr2",
        handle: "test_attr2",
        description: "Test description 2",
        values: [],
      )
      Attribute.stubs(:all).returns([@attribute, attribute2])

      assert_raises(ArgumentError) do
        LocalizationsValidator.validate!(["fr"])
      end
    end

    test "validate! raises error when value localizations are missing" do
      value2 = Value.new(
        id: 2,
        name: "Second Value",
        friendly_id: "test_value2",
        handle: "test_value2",
      )
      Value.stubs(:all).returns([@value, value2])

      assert_raises(ArgumentError) do
        LocalizationsValidator.validate!(["fr"])
      end
    end

    test "validate! raises error when locales are inconsistent" do
      Dir.unstub(:glob)
      Dir.stubs(:glob)
        .with("/fake/path/localizations/categories/*.yml")
        .returns(["/fake/path/localizations/categories/fr.yml"])
      Dir.stubs(:glob)
        .with("/fake/path/localizations/attributes/*.yml")
        .returns(["/fake/path/localizations/attributes/fr.yml"])
      Dir.stubs(:glob)
        .with("/fake/path/localizations/values/*.yml")
        .returns([])

      assert_raises(ArgumentError, "Not all model localizations have the same set of locales") do
        LocalizationsValidator.validate!
      end
    end
  end
end
