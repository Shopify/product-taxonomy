# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class DumpIntegrationFullNamesCommandTest < TestCase
    setup do
      @tmp_base_path = Dir.mktmpdir
      @integrations_path = File.expand_path("data/integrations", @tmp_base_path)

      FileUtils.mkdir_p(@integrations_path)
      File.write(File.expand_path("VERSION", @tmp_base_path), "2023-12")

      DumpIntegrationFullNamesCommand.any_instance.stubs(:integration_data_path).returns(@integrations_path)
      Command.any_instance.stubs(:load_taxonomy)
      Command.any_instance.stubs(:version_file_path).returns(File.expand_path("VERSION", @tmp_base_path))

      integrations_data = [
        {
          "name" => "shopify",
          "available_versions" => ["shopify/2023-12"]
        }
      ]
      File.write(File.expand_path("integrations.yml", @integrations_path), YAML.dump(integrations_data))
    end

    teardown do
      FileUtils.remove_entry(@tmp_base_path)
    end

    test "initialize sets version from options when provided" do
      command = DumpIntegrationFullNamesCommand.new(version: "2024-01")
      assert_equal "2024-01", command.instance_variable_get(:@version)
    end

    test "initialize sets version from version file when not provided in options" do
      command = DumpIntegrationFullNamesCommand.new({})
      assert_equal "2023-12", command.instance_variable_get(:@version)
    end

    test "execute creates directory structure when it doesn't exist" do
      Serializers::Category::Data::FullNamesSerializer.stubs(:serialize_all).returns(["test_data"])
      target_dir = File.expand_path("shopify/2023-12", @integrations_path)
      refute File.exist?(target_dir)

      command = DumpIntegrationFullNamesCommand.new({})
      command.execute

      assert File.exist?(target_dir)
    end

    test "execute dumps data to YAML file with correct path" do
      Serializers::Category::Data::FullNamesSerializer.stubs(:serialize_all).returns(["test_data"])

      command = DumpIntegrationFullNamesCommand.new({})
      command.execute

      expected_path = File.expand_path("shopify/2023-12/full_names.yml", @integrations_path)
      assert File.exist?(expected_path)
      assert_equal "---\n- test_data\n", File.read(expected_path)
    end

    test "execute adds new version to integrations.yml when using a new version" do
      target_dir = File.expand_path("shopify/2024-02", @integrations_path)
      refute File.exist?(target_dir)

      command = DumpIntegrationFullNamesCommand.new(version: "2024-02")
      Serializers::Category::Data::FullNamesSerializer.stubs(:serialize_all).returns(["test_data"])
      command.execute

      assert File.exist?(target_dir)
      integrations_file = File.expand_path("integrations.yml", @integrations_path)
      updated_integrations = YAML.load_file(integrations_file)
      assert_includes updated_integrations[0]["available_versions"], "shopify/2024-02"
    end

    test "execute doesn't modify integrations.yml when using existing version" do
      command = DumpIntegrationFullNamesCommand.new({})
      Serializers::Category::Data::FullNamesSerializer.stubs(:serialize_all).returns(["test_data"])
      command.execute

      integrations_file = File.expand_path("integrations.yml", @integrations_path)
      updated_integrations = YAML.load_file(integrations_file)
      assert_equal ["shopify/2023-12"], updated_integrations[0]["available_versions"]
    end
  end
end
