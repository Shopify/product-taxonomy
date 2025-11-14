# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class DumpReturnReasonsCommandTest < TestCase
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

    test "execute dumps return reasons to YAML file" do
      mock_data = [
        {
          "id" => 1,
          "name" => "Defective or Doesn't Work",
          "description" => "Item is broken, defective, or doesn't function as expected",
          "friendly_id" => "defective_or_doesnt_work",
          "handle" => "defective-or-doesnt-work",
        },
        {
          "id" => 2,
          "name" => "Wrong Size or Fit",
          "description" => "Item doesn't fit properly or is not the expected size",
          "friendly_id" => "wrong_size_or_fit",
          "handle" => "wrong-size-or-fit",
        },
      ]
      Serializers::ReturnReason::Data::DataSerializer.stubs(:serialize_all)
        .returns(mock_data)

      command = DumpReturnReasonsCommand.new({})
      command.execute

      expected_path = File.expand_path("data/return_reasons.yml", @tmp_base_path)
      assert File.exist?(expected_path)

      dumped_data = YAML.load_file(expected_path)
      assert_equal mock_data, dumped_data
    end

    test "execute creates directory if it doesn't exist" do
      # Remove the data directory to test directory creation
      FileUtils.rm_rf(File.expand_path("data", @tmp_base_path))

      mock_data = { "test" => "data" }
      Serializers::ReturnReason::Data::DataSerializer.stubs(:serialize_all)
        .returns(mock_data)

      command = DumpReturnReasonsCommand.new({})
      command.execute

      expected_path = File.expand_path("data/return_reasons.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      assert File.directory?(File.dirname(expected_path))
    end

    test "execute writes YAML without line wrapping" do
      mock_data = [{
        "id" => 1,
        "name" => "This is a very long name that would normally be wrapped in standard YAML output",
        "description" => "This is an extremely long description that would definitely be wrapped in standard YAML output if we did not use the line_width option set to negative one",
        "friendly_id" => "this_is_a_very_long_name_that_would_normally_be_wrapped_in_standard_yaml_output",
        "handle" => "this-is-a-very-long-name-that-would-normally-be-wrapped-in-standard-yaml-output",
      }]
      Serializers::ReturnReason::Data::DataSerializer.stubs(:serialize_all)
        .returns(mock_data)

      command = DumpReturnReasonsCommand.new({})
      command.execute

      expected_path = File.expand_path("data/return_reasons.yml", @tmp_base_path)
      file_contents = File.read(expected_path)

      # Check that long strings are not wrapped
      assert_match(/name: This is a very long name that would normally be wrapped in standard YAML output$/, file_contents)
      assert_match(/description: This is an extremely long description that would definitely be wrapped in standard YAML output if we did not use the line_width option set to negative one$/, file_contents)
    end
  end
end
