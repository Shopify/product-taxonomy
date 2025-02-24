# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class DumpAttributesCommandTest < TestCase
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

    test "execute dumps attributes to YAML file" do
      mock_data = { "test" => "data" }
      Serializers::Attribute::Data::DataSerializer.stubs(:serialize_all)
        .returns(mock_data)

      command = DumpAttributesCommand.new({})
      command.execute

      expected_path = File.expand_path("data/attributes.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      assert_equal "---\ntest: data\n", File.read(expected_path)
    end
  end
end
