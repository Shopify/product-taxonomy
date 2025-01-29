# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class LocalizedTest < TestCase
    class TestClass
      extend Localized

      localized_attr_reader :name, keyed_by: :id

      attr_reader :id, :non_localized_attr

      def initialize(id:, name:, non_localized_attr:)
        @id = id
        @name = name
        @non_localized_attr = non_localized_attr
      end
    end

    setup do
      @test_instance = TestClass.new(id: 1, name: "Raw name", non_localized_attr: "Non-localized attr")
      @fr_yaml = <<~YAML
        fr:
          testclasses:
            "1":
              name: "Nom en français"
      YAML

      @es_yaml = <<~YAML
        es:
          testclasses:
            "1":
              name: "Nombre en español"
      YAML

      Dir.stubs(:glob).returns(["fake/path/fr.yml", "fake/path/es.yml"])
      YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(@fr_yaml))
      YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(@es_yaml))
    end

    teardown do
      TestClass.instance_variable_set(:@localizations, nil)
    end

    test "localized_attr_reader defines methods that return localized attributes, using raw value if locale is en" do
      assert_equal "Raw name", @test_instance.name
      assert_equal "Raw name", @test_instance.name(locale: "en")
    end

    test "localized_attr_reader returns translated value for non-English locales" do
      assert_equal "Nom en français", @test_instance.name(locale: "fr")
      assert_equal "Nombre en español", @test_instance.name(locale: "es")
    end

    test "localized_attr_reader falls back to en value if locale is not found" do
      assert_equal "Raw name", @test_instance.name(locale: "cs")
      assert_equal "Raw name", @test_instance.name(locale: "da")
    end

    test "localized_attr_reader does not change non-localized attributes" do
      assert_equal "Non-localized attr", @test_instance.non_localized_attr
    end

    test "validate_localizations! passes when all required localizations are present" do
      TestClass.stubs(:all).returns([@test_instance])

      assert_nothing_raised do
        TestClass.validate_localizations!
        TestClass.validate_localizations!(["fr"])
        TestClass.validate_localizations!(["es"])
        TestClass.validate_localizations!(["fr", "es"])
      end
    end

    test "validate_localizations! raises error when localizations are missing" do
      test_instance2 = TestClass.new(id: 2, name: "Second", non_localized_attr: "Non-localized attr")
      TestClass.stubs(:all).returns([@test_instance, test_instance2])

      assert_raises(ArgumentError) do
        TestClass.validate_localizations!(["fr"])
      end
    end

    test "validate_localizations! raises error when localizations are incomplete" do
      fr_yaml = <<~YAML
        fr:
          testclasses:
            "1":
              name: # Missing name
      YAML

      Dir.unstub(:glob)
      Dir.stubs(:glob).returns(["fake/path/fr.yml"])
      YAML.unstub(:safe_load_file)
      YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
      TestClass.stubs(:all).returns([@test_instance])

      assert_raises(ArgumentError) do
        TestClass.validate_localizations!(["fr"])
      end
    end
  end
end
