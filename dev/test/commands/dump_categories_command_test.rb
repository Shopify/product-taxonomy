# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class DumpCategoriesCommandTest < TestCase
    setup do
      @tmp_base_path = Dir.mktmpdir
      @real_base_path = File.expand_path("..", ProductTaxonomy.data_path)

      FileUtils.mkdir_p(File.expand_path("data/categories", @tmp_base_path))
      ProductTaxonomy.stubs(:data_path).returns(File.expand_path("data", @tmp_base_path))

      Command.any_instance.stubs(:load_taxonomy)
      @mock_vertical = stub(
        id: "test_vertical",
        name: "Test Vertical",
        friendly_name: "tv_test_vertical",
        root?: true,
      )
    end

    teardown do
      FileUtils.remove_entry(@tmp_base_path)
    end

    test "initialize sets verticals to all verticals when not specified" do
      Category.stubs(:verticals).returns([@mock_vertical])
      command = DumpCategoriesCommand.new({})
      assert_equal ["test_vertical"], command.instance_variable_get(:@verticals)
    end

    test "initialize accepts custom verticals" do
      command = DumpCategoriesCommand.new(verticals: ["custom_vertical"])
      assert_equal ["custom_vertical"], command.instance_variable_get(:@verticals)
    end

    test "execute dumps specified vertical to YAML file" do
      Category.stubs(:find_by).with(id: "test_vertical").returns(@mock_vertical)
      Serializers::Category::Data::DataSerializer.stubs(:serialize_all)
        .with(@mock_vertical)
        .returns({ "test" => "data" })

      command = DumpCategoriesCommand.new(verticals: ["test_vertical"])
      command.execute

      expected_path = File.expand_path("data/categories/tv_test_vertical.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      assert_equal "---\ntest: data\n", File.read(expected_path)
    end

    test "execute raises error when vertical is not found" do
      Category.stubs(:find_by).with(id: "nonexistent").returns(nil)

      command = DumpCategoriesCommand.new(verticals: ["nonexistent"])
      assert_raises(RuntimeError) do
        command.execute
      end
    end

    test "execute raises error when category is not a vertical" do
      non_vertical = stub(
        id: "non_vertical",
        name: "Non Vertical",
        friendly_name: "nv_non_vertical",
        root?: false,
      )
      Category.stubs(:find_by).with(id: "non_vertical").returns(non_vertical)

      command = DumpCategoriesCommand.new(verticals: ["non_vertical"])
      assert_raises(RuntimeError) do
        command.execute
      end
    end

    test "execute dumps multiple verticals" do
      second_vertical = stub(
        id: "second_vertical",
        name: "Second Vertical",
        friendly_name: "sv_second_vertical",
        root?: true,
      )

      Category.stubs(:find_by).with(id: "test_vertical").returns(@mock_vertical)
      Category.stubs(:find_by).with(id: "second_vertical").returns(second_vertical)

      Serializers::Category::Data::DataSerializer.stubs(:serialize_all)
        .with(@mock_vertical)
        .returns({ "test" => "data1" })
      Serializers::Category::Data::DataSerializer.stubs(:serialize_all)
        .with(second_vertical)
        .returns({ "test" => "data2" })

      command = DumpCategoriesCommand.new(verticals: ["test_vertical", "second_vertical"])
      command.execute

      first_path = File.expand_path("data/categories/tv_test_vertical.yml", @tmp_base_path)
      second_path = File.expand_path("data/categories/sv_second_vertical.yml", @tmp_base_path)

      assert File.exist?(first_path)
      assert File.exist?(second_path)
      assert_equal "---\ntest: data1\n", File.read(first_path)
      assert_equal "---\ntest: data2\n", File.read(second_path)
    end
  end
end
