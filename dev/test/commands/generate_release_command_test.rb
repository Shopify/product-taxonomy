# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class GenerateReleaseCommandTest < TestCase
    setup do
      @tmp_base_path = Dir.mktmpdir
      @version = "2024-01"
      @next_version = "2024-02-unstable"
      @version_file_path = File.expand_path("VERSION", @tmp_base_path)
      @release_branch = "release-v#{@version}"

      # Create test files and directories
      FileUtils.mkdir_p(File.expand_path("dist", @tmp_base_path))
      FileUtils.mkdir_p(File.expand_path("data/integrations/shopify/mappings", @tmp_base_path))

      # Create VERSION file
      File.write(@version_file_path, "2023-12")

      # Create README files
      File.write(
        File.expand_path("README.md", @tmp_base_path),
        '<img src="https://img.shields.io/badge/Version-2023--12-blue.svg" alt="Version">',
      )
      File.write(
        File.expand_path("dist/README.md", @tmp_base_path),
        '<img src="https://img.shields.io/badge/Version-2023--12-blue.svg" alt="Version">',
      )

      # Create test mapping files
      File.write(
        File.expand_path("data/integrations/shopify/mappings/to_shopify.yml", @tmp_base_path),
        "output_version: 2023-12-unstable"
      )
      File.write(
        File.expand_path("data/integrations/shopify/mappings/from_shopify.yml", @tmp_base_path),
        "input_version: 2023-12-unstable"
      )

      # Stub dependencies
      Command.any_instance.stubs(:version_file_path).returns(@version_file_path)
      Command.any_instance.stubs(:load_taxonomy)
      ProductTaxonomy.stubs(:data_path).returns("#{@tmp_base_path}/data")

      # Stub git operations
      command_stub = GenerateReleaseCommand.any_instance
      command_stub.stubs(:run_git_command).returns(true)
      command_stub.stubs(:get_commit_hash).returns("abc1234")
      command_stub.stubs(:git_repo_root).returns(@tmp_base_path)

      # Stub git branch and status check to pass by default
      command_stub.stubs(:`).with("git rev-parse --abbrev-ref HEAD").returns("main\n")
      command_stub.stubs(:`).with("git status --porcelain").returns("")

      # Stub command executions
      GenerateDistCommand.any_instance.stubs(:execute)
      GenerateDocsCommand.any_instance.stubs(:execute)
      DumpIntegrationFullNamesCommand.any_instance.stubs(:execute)
    end

    teardown do
      FileUtils.remove_entry(@tmp_base_path)
    end

    test "initialize sets version from options if provided" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)
      assert_equal @version, command.instance_variable_get(:@version)
      assert_equal @next_version, command.instance_variable_get(:@next_version)
    end

    test "initialize raises error if next_version doesn't end with -unstable" do
      assert_raises ArgumentError do
        GenerateReleaseCommand.new(next_version: "2024-02")
      end
    end

    test "initialize sets all locales when 'all' is specified" do
      Command.any_instance.stubs(:locales_defined_in_data_path).returns(["en", "fr", "es"])
      command = GenerateReleaseCommand.new(next_version: @next_version, locales: ["all"])
      assert_equal ["en", "fr", "es"], command.instance_variable_get(:@locales)
    end

    test "initialize sets specific locales when provided" do
      command = GenerateReleaseCommand.new(next_version: @next_version, locales: ["en", "fr"])
      assert_equal ["en", "fr"], command.instance_variable_get(:@locales)
    end

    test "execute performs release version steps and next version steps" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version, locales: ["en"])

      command.expects(:run_git_command).with("pull")
      command.expects(:run_git_command).with("checkout", "-b", @release_branch)
      command.expects(:run_git_command).with("add", ".").times(2)
      command.expects(:run_git_command).with("commit", "-m", "Release version #{@version}")
      command.expects(:run_git_command).with("commit", "-m", "Bump version to #{@next_version}")
      command.expects(:run_git_command).with("tag", "v#{@version}")
      GenerateDistCommand.any_instance.expects(:execute).times(2)
      GenerateDocsCommand.any_instance.expects(:execute).times(2)
      DumpIntegrationFullNamesCommand.any_instance.expects(:execute)

      command.execute

      assert_equal @next_version, File.read(@version_file_path)
    end

    test "execute raises error when not on main branch" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)

      command.unstub(:`);
      command.stubs(:`).with("git rev-parse --abbrev-ref HEAD").returns("feature/new-stuff\n")
      command.stubs(:`).with("git status --porcelain").returns("")

      assert_raises(RuntimeError) do
        command.execute
      end
    end

    test "execute raises error when working directory is not clean" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)

      command.unstub(:`);
      command.stubs(:`).with("git rev-parse --abbrev-ref HEAD").returns("main\n")
      command.stubs(:`).with("git status --porcelain").returns(" M dev/lib/product_taxonomy/commands/generate_release_command.rb\n")

      assert_raises(RuntimeError) do
        command.execute
      end
    end

    test "execute updates integration mapping files" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)

      command.execute

      to_shopify_content = File.read(File.expand_path("data/integrations/shopify/mappings/to_shopify.yml", @tmp_base_path))
      from_shopify_content = File.read(File.expand_path("data/integrations/shopify/mappings/from_shopify.yml", @tmp_base_path))

      assert_equal "output_version: #{@version}", to_shopify_content
      assert_equal "input_version: #{@version}", from_shopify_content
    end

    test "execute updates both README files version badges" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)

      command.execute

      root_readme_content = File.read(File.expand_path("README.md", @tmp_base_path))
      dist_readme_content = File.read(File.expand_path("dist/README.md", @tmp_base_path))

      expected_badge = '<img src="https://img.shields.io/badge/Version-2024--01-blue.svg" alt="Version">'
      assert_equal expected_badge, root_readme_content
      assert_equal expected_badge, dist_readme_content
    end

    test "print_summary outputs expected format" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)
      expected_output = <<~OUTPUT

        ====== Release Summary ======
        - Created commit (abc1234): Release version 2024-01
        - Created commit (abc1234): Bump version to 2024-02-unstable
        - Created tag: v2024-01

        Inspect changes with:
          git show abc1234
          git show abc1234
          git show v2024-01

        Next steps:
          1. If the changes look good, push the branch
             * Run `git push origin release-v2024-01`
          2. Open a PR and follow the usual process to get approval and merge
             * https://github.com/Shopify/product-taxonomy/pull/new/release-v2024-01
          3. Once the PR is merged, push the tag that was created
             * Run `git push origin v2024-01`
          4. Create a release on GitHub
             * https://github.com/Shopify/product-taxonomy/releases/new?tag=v2024-01
      OUTPUT
      log_string = StringIO.new
      logger = Logger.new(log_string)
      logger.formatter = proc { |_, _, _, msg| "#{msg}\n" }
      command.instance_variable_set(:@logger, logger)

      command.send(:print_summary, "abc1234", "abc1234")

      assert_equal expected_output, log_string.string
    end

    test "print_rollback_instructions outputs expected format when branch and tag exist" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)
      expected_output = <<~OUTPUT

        ====== Rollback Instructions ======
        The release was aborted due to an error.
        You can use the following commands to roll back to the original state:
          git reset --hard main
          git branch -D release-v2024-01
          git tag -d v2024-01
      OUTPUT
      log_string = StringIO.new
      logger = Logger.new(log_string)
      logger.formatter = proc { |_, _, _, msg| "#{msg}\n" }
      command.instance_variable_set(:@logger, logger)

      # Stub system calls to simulate branch and tag existing
      command.stubs(:system).with("git", "show-ref", "--verify", "--quiet", "refs/heads/release-v#{@version}").returns(true)
      command.stubs(:system).with("git", "show-ref", "--verify", "--quiet", "refs/tags/v#{@version}").returns(true)

      command.send(:print_rollback_instructions)

      assert_equal expected_output, log_string.string
    end

    test "print_rollback_instructions outputs expected format when branch and tag don't exist" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)
      expected_output = <<~OUTPUT

        ====== Rollback Instructions ======
        The release was aborted due to an error.
        You can use the following commands to roll back to the original state:
          git reset --hard main
      OUTPUT
      log_string = StringIO.new
      logger = Logger.new(log_string)
      logger.formatter = proc { |_, _, _, msg| "#{msg}\n" }
      command.instance_variable_set(:@logger, logger)

      # Stub system calls to simulate branch and tag not existing
      command.stubs(:system).with("git", "show-ref", "--verify", "--quiet", "refs/heads/release-v#{@version}").returns(false)
      command.stubs(:system).with("git", "show-ref", "--verify", "--quiet", "refs/tags/v#{@version}").returns(false)

      command.send(:print_rollback_instructions)

      assert_equal expected_output, log_string.string
    end

    test "execute handles errors and prints rollback instructions" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)

      # Simulate failure during execution
      command.expects(:generate_release_version!).raises(StandardError.new("Test error"))
      command.expects(:print_rollback_instructions)

      assert_raises(StandardError) do
        command.execute
      end
    end

    test "run_git_command raises error when git command fails" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)

      GenerateReleaseCommand.any_instance.unstub(:run_git_command)
      command.stubs(:git_repo_root).returns(@tmp_base_path)
      command.expects(:system).with("git", "checkout", "main", chdir: @tmp_base_path).returns(false)
      command.expects(:raise).with(regexp_matches(/Git command failed/))

      command.send(:run_git_command, "checkout", "main")
    end

    test "git_repo_root memoizes git repository root path" do
      GenerateReleaseCommand.any_instance.unstub(:git_repo_root)
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)

      command.expects(:`).with("git rev-parse --show-toplevel").returns("/repo/path\n").once

      assert_equal "/repo/path", command.send(:git_repo_root)
      assert_equal "/repo/path", command.send(:git_repo_root) # Should use memoized value
    end
  end
end
