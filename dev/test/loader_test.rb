# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

module ProductTaxonomy
  class LoaderTest < TestCase
    # Stand-in for a deserialization gadget: records whether Psych constructed it.
    class DeserializationProbe
      class << self
        attr_accessor :constructed
      end

      def init_with(_coder)
        self.class.constructed = true
      end
    end

    SOURCE_FILES = {
      "values.yml" => "[]\n",
      "attributes.yml" => "base_attributes: []\nextended_attributes: []\n",
      "return_reasons.yml" => "[]\n",
      "disclosures.yml" => "[]\n",
    }.freeze

    setup do
      @data_path = Dir.mktmpdir
      FileUtils.mkdir_p(File.join(@data_path, "categories"))
      SOURCE_FILES.each { |file, contents| File.write(File.join(@data_path, file), contents) }
      DeserializationProbe.constructed = false
    end

    teardown do
      FileUtils.remove_entry(@data_path)
    end

    SOURCE_FILES.each_key do |file|
      test "load rejects Ruby object tags in #{file} before constructing the object" do
        File.write(File.join(@data_path, file), "--- !ruby/object:#{DeserializationProbe.name} {}\n")

        assert_raises(Psych::DisallowedClass) { Loader.load(data_path: @data_path) }
        refute DeserializationProbe.constructed, "#{file} was deserialized into a Ruby object"
      end

      test "load parses #{file} with safe_load, permitting no Ruby-specific types" do
        File.write(File.join(@data_path, file), "--- !ruby/symbol probe\n")

        assert_raises(Psych::DisallowedClass) { Loader.load(data_path: @data_path) }
      end
    end
  end
end
