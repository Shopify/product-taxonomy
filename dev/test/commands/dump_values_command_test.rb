# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class DumpValuesCommandTest < TestCase
    setup do
      @tmp_base_path = Dir.mktmpdir
      @real_base_path = File.expand_path("..", ProductTaxonomy.data_path)

      FileUtils.mkdir_p(File.expand_path("data", @tmp_base_path))
      ProductTaxonomy.stubs(:data_path).returns(File.expand_path("data", @tmp_base_path))

      Command.any_instance.stubs(:load_taxonomy)
    end

    teardown do
      FileUtils.remove_entry(@tmp_base_path)
    end

    test "execute dumps values to YAML file" do
      mock_data = [{ "id" => 1, "name" => "Test Value", "friendly_id" => "test__value", "handle" => "test__value" }]
      Serializers::Value::Data::DataSerializer.stubs(:serialize_all)
        .returns(mock_data)

      command = DumpValuesCommand.new({})
      command.execute

      expected_path = File.expand_path("data/values.yml", @tmp_base_path)
      expected_content = "---\n- id: 1\n  name: Test Value\n  friendly_id: test__value\n  handle: test__value\n"
      assert File.exist?(expected_path)
      assert_equal expected_content, File.read(expected_path)
    end
  end
end
