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

    test "localized_attr_reader defines methods that return localized attributes, using raw value if locale is en" do
      test_instance = TestClass.new(id: 1, name: "Raw name", non_localized_attr: "Non-localized attr")
      assert_equal "Raw name", test_instance.name
      assert_equal "Raw name", test_instance.name(locale: "en")
    end

    test "localized_attr_reader returns translated value for non-English locales" do
      test_instance = TestClass.new(id: 1, name: "Raw name", non_localized_attr: "Non-localized attr")
      assert_equal "Nom en français", test_instance.name(locale: "fr")
      assert_equal "Nombre en español", test_instance.name(locale: "es")
    end

    test "localized_attr_reader falls back to en value if locale is not found" do
      test_instance = TestClass.new(id: 1, name: "Raw name", non_localized_attr: "Non-localized attr")
      assert_equal "Raw name", test_instance.name(locale: "cs")
      assert_equal "Raw name", test_instance.name(locale: "da")
    end

    test "localized_attr_reader does not change non-localized attributes" do
      test_instance = TestClass.new(id: 1, name: "Raw name", non_localized_attr: "Non-localized attr")
      assert_equal "Non-localized attr", test_instance.non_localized_attr
    end
  end
end
