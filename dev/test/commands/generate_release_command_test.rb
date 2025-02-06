# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class GenerateReleaseCommandTest < TestCase
    setup do
      @tmp_base_path = Dir.mktmpdir
      @version = "2024-01"
      @version_file_path = File.expand_path("VERSION", @tmp_base_path)

      # Create test files and directories
      FileUtils.mkdir_p(File.expand_path("dist", @tmp_base_path))
      File.write(@version_file_path, "2023-12")
      File.write(
        File.expand_path("dist/README.md", @tmp_base_path),
        '<img src="https://img.shields.io/badge/Version-2023--12-blue.svg" alt="Version">',
      )

      # Stub dependencies
      Command.any_instance.stubs(:version_file_path).returns(@version_file_path)
      Command.any_instance.stubs(:load_taxonomy)
      Command.any_instance.stubs(:system).with("git", "tag", "v#{@version}").returns(true)
      GenerateDistCommand.any_instance.stubs(:execute)
      GenerateDocsCommand.any_instance.stubs(:execute)
      ProductTaxonomy.stubs(:data_path).returns("#{@tmp_base_path}/data")
    end

    teardown do
      FileUtils.remove_entry(@tmp_base_path)
    end

    test "initialize sets version from options if provided" do
      command = GenerateReleaseCommand.new(version: @version)
      assert_equal @version, command.instance_variable_get(:@version)
    end

    test "initialize reads version from file if not provided in options" do
      command = GenerateReleaseCommand.new({})
      assert_equal "2023-12", command.instance_variable_get(:@version)
    end

    test "initialize sets all locales when 'all' is specified" do
      Command.any_instance.stubs(:locales_defined_in_data_path).returns(["en", "fr", "es"])
      command = GenerateReleaseCommand.new(locales: ["all"])
      assert_equal ["en", "fr", "es"], command.instance_variable_get(:@locales)
    end

    test "initialize sets specific locales when provided" do
      command = GenerateReleaseCommand.new(locales: ["en", "fr"])
      assert_equal ["en", "fr"], command.instance_variable_get(:@locales)
    end

    test "execute performs all required steps in order" do
      command = GenerateReleaseCommand.new(version: @version, locales: ["en"])

      # Set up expectations
      GenerateDistCommand.any_instance.expects(:execute)
      GenerateDocsCommand.any_instance.expects(:execute)

      command.execute

      # Verify VERSION file was updated
      assert_equal @version, File.read(@version_file_path)
    end

    test "execute updates README.md version badge" do
      command = GenerateReleaseCommand.new(version: @version)

      command.execute

      readme_content = File.read(File.expand_path("dist/README.md", @tmp_base_path))
      assert_equal '<img src="https://img.shields.io/badge/Version-2024--01-blue.svg" alt="Version">', readme_content
    end
  end
end
