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
        "output_taxonomy: shopify/2023-12-unstable",
      )
      File.write(
        File.expand_path("data/integrations/shopify/mappings/from_shopify.yml", @tmp_base_path),
        "input_taxonomy: shopify/2023-12-unstable",
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

    test "initialize raises error if current_version ends with -unstable" do
      assert_raises ArgumentError do
        GenerateReleaseCommand.new(current_version: "2024-01-unstable", next_version: @next_version)
      end
    end

    test "initialize raises error if next_version doesn't end with -unstable" do
      assert_raises ArgumentError do
        GenerateReleaseCommand.new(current_version: @version, next_version: "2024-02")
      end
    end

    test "initialize sets all locales when 'all' is specified" do
      Command.any_instance.stubs(:locales_defined_in_data_path).returns(["en", "fr", "es"])
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version, locales: ["all"])
      assert_equal ["en", "fr", "es"], command.instance_variable_get(:@locales)
    end

    test "initialize sets specific locales when provided" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version, locales: ["en", "fr"])
      assert_equal ["en", "fr"], command.instance_variable_get(:@locales)
    end

    test "execute performs release version steps and next version steps" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version, locales: ["en"])

      command.expects(:run_git_command).with("pull")
      command.expects(:run_git_command).with("checkout", "-b", @release_branch)
      command.expects(:run_git_command).with("checkout", "-b", "bump-v#{@next_version}")
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

      command.unstub(:`)
      command.stubs(:`).with("git rev-parse --abbrev-ref HEAD").returns("feature/new-stuff\n")
      command.stubs(:`).with("git status --porcelain").returns("")

      assert_raises(RuntimeError) do
        command.execute
      end
    end

    test "execute raises error when working directory is not clean" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)

      command.unstub(:`)
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

      assert_equal "output_taxonomy: shopify/#{@version}", to_shopify_content
      assert_equal "input_taxonomy: shopify/#{@next_version}", from_shopify_content
    end

    test "execute updates taxonomy fields in mapping files" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)
      command.execute

      # After execute, to_shopify should have the stable version
      to_shopify_content = File.read(File.expand_path("data/integrations/shopify/mappings/to_shopify.yml", @tmp_base_path))
      assert_match "output_taxonomy: shopify/#{@version}", to_shopify_content
      refute_match "output_taxonomy: shopify/2023-12-unstable", to_shopify_content

      # After execute, from_shopify should have the next unstable version
      from_shopify_content = File.read(File.expand_path("data/integrations/shopify/mappings/from_shopify.yml", @tmp_base_path))
      assert_match "input_taxonomy: shopify/#{@next_version}", from_shopify_content
      refute_match "input_taxonomy: shopify/2023-12-unstable", from_shopify_content
    end

    test "execute updates input and output taxonomies for integrations in two stages" do
      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)

      # Initial state (from setup) for reference:
      # to_shopify.yml contains "output_taxonomy: shopify/2023-12-unstable"
      # from_shopify.yml contains "input_taxonomy: shopify/2023-12-unstable"

      # Basically the call sequence for execute is:
      # 1. check_git_state!
      # 2. generate_release_version!
      # 3. move_to_next_version!
      command.send(:check_git_state!)
      command.send(:generate_release_version!)

      to_shopify_content_stage1 = File.read(File.expand_path("data/integrations/shopify/mappings/to_shopify.yml", @tmp_base_path))
      from_shopify_content_stage1 = File.read(File.expand_path("data/integrations/shopify/mappings/from_shopify.yml", @tmp_base_path))

      assert_match "output_taxonomy: shopify/#{@version}",
        to_shopify_content_stage1,
        "After stage 1, to_shopify.yml output_taxonomy should be stable version (#{@version})"
      assert_match "input_taxonomy: shopify/#{@version}",
        from_shopify_content_stage1,
        "After stage 1, from_shopify.yml input_taxonomy should be stable version (#{@version})"

      refute_match "shopify/2023-12-unstable", to_shopify_content_stage1 unless "shopify/#{@version}" == "shopify/2023-12-unstable"
      refute_match "shopify/2023-12-unstable", from_shopify_content_stage1 unless "shopify/#{@version}" == "shopify/2023-12-unstable"

      command.send(:move_to_next_version!)

      to_shopify_content_stage2 = File.read(File.expand_path("data/integrations/shopify/mappings/to_shopify.yml", @tmp_base_path))
      from_shopify_content_stage2 = File.read(File.expand_path("data/integrations/shopify/mappings/from_shopify.yml", @tmp_base_path))

      assert_match "output_taxonomy: shopify/#{@version}",
        to_shopify_content_stage2,
        "After stage 2, to_shopify.yml output_taxonomy should remain stable version (#{@version})"
      refute_match "shopify/#{@next_version}",
        to_shopify_content_stage2,
        "After stage 2, to_shopify.yml output_taxonomy should NOT be next_version (#{@next_version})"

      assert_match "input_taxonomy: shopify/#{@next_version}",
        from_shopify_content_stage2,
        "After stage 2, from_shopify.yml input_taxonomy should be next unstable version (#{@next_version})"
      refute_match "input_taxonomy: shopify/#{@version}", from_shopify_content_stage2 unless @version == @next_version.gsub(/-unstable$/, "")
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
        - Created branch: release-v2024-01
          - Commit (abc1234): Release version 2024-01
          - Tag: v2024-01
        - Created branch: bump-v2024-02-unstable
          - Commit (abc1234): Bump version to 2024-02-unstable

        Inspect changes with:
          git show abc1234
          git show abc1234
          git show v2024-01

        Next steps:
          1. If the changes look good, push both branches
             * Run `git push origin release-v2024-01`
             * Run `git push origin bump-v2024-02-unstable`
          2. Open a PR and follow the usual process to get approval and merge the release branch
             * https://github.com/Shopify/product-taxonomy/pull/new/release-v2024-01
             * Target: main
          3. Open a PR and follow the usual process to get approval and merge the bump branch
             * https://github.com/Shopify/product-taxonomy/pull/new/bump-v2024-02-unstable
             * Target: release-v2024-01 (NOT main)
             * This PR should be set to merge into release-v2024-01
          4. Merge PRs in order
             * First: Merge the release PR into main
             * Second: Update the bump PR to target main, then merge
          5. Once the PRs are merged, push the tag that was created
             * Run `git push origin v2024-01`
          6. Create a release on GitHub
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
          git checkout main
          git reset --hard origin/main
          git branch -D release-v2024-01
          git branch -D bump-v2024-02-unstable
          git tag -d v2024-01
      OUTPUT
      log_string = StringIO.new
      logger = Logger.new(log_string)
      logger.formatter = proc { |_, _, _, msg| "#{msg}\n" }
      command.instance_variable_set(:@logger, logger)

      # Stub system calls to simulate branch and tag existing
      command.stubs(:system).with("git", "show-ref", "--verify", "--quiet", "refs/heads/release-v#{@version}").returns(true)
      command.stubs(:system).with("git", "show-ref", "--verify", "--quiet", "refs/heads/bump-v#{@next_version}").returns(true)
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
          git checkout main
          git reset --hard origin/main
      OUTPUT
      log_string = StringIO.new
      logger = Logger.new(log_string)
      logger.formatter = proc { |_, _, _, msg| "#{msg}\n" }
      command.instance_variable_set(:@logger, logger)

      # Stub system calls to simulate branch and tag not existing
      command.stubs(:system).with("git", "show-ref", "--verify", "--quiet", "refs/heads/release-v#{@version}").returns(false)
      command.stubs(:system).with("git", "show-ref", "--verify", "--quiet", "refs/heads/bump-v#{@next_version}").returns(false)
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

    test "update_mapping_files skips shopify version directories" do
      FileUtils.mkdir_p(File.expand_path("data/integrations/shopify/2023-11/mappings", @tmp_base_path))
      shopify_version_file = File.expand_path("data/integrations/shopify/2023-11/mappings/to_shopify.yml", @tmp_base_path)
      File.write(shopify_version_file, "output_taxonomy: shopify/2023-12-unstable")

      FileUtils.mkdir_p(File.expand_path("data/integrations/other/mappings", @tmp_base_path))
      other_integration_file = File.expand_path("data/integrations/other/mappings/to_shopify.yml", @tmp_base_path)
      File.write(other_integration_file, "output_taxonomy: shopify/2023-12-unstable")

      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)
      command.send(:update_mapping_files, "to_shopify.yml", "output_taxonomy", "shopify/#{@version}")

      assert_equal "output_taxonomy: shopify/2023-12-unstable", File.read(shopify_version_file)
      assert_equal "output_taxonomy: shopify/#{@version}", File.read(other_integration_file)
    end

    test "create_previous_version_mappings creates mappings for latest version without mappings" do
      FileUtils.mkdir_p(File.expand_path("data/integrations/shopify/2023-10/mappings", @tmp_base_path))
      FileUtils.mkdir_p(File.expand_path("data/integrations/shopify/2023-11", @tmp_base_path))
      FileUtils.mkdir_p(File.expand_path("data/integrations/shopify/2023-12", @tmp_base_path))

      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)
      command.send(:create_previous_version_mappings)

      mappings_file = File.expand_path("data/integrations/shopify/2023-12/mappings/to_shopify.yml", @tmp_base_path)
      assert File.exist?(mappings_file), "Mappings file should be created"
      
      content = File.read(mappings_file)
      assert_match "input_taxonomy: shopify/2023-12", content
      assert_match "output_taxonomy: shopify/#{@version}", content
      assert_match "rules: []", content
    end

    test "create_previous_version_mappings does nothing if all versions have mappings" do
      FileUtils.mkdir_p(File.expand_path("data/integrations/shopify/2023-10/mappings", @tmp_base_path))
      FileUtils.mkdir_p(File.expand_path("data/integrations/shopify/2023-11/mappings", @tmp_base_path))
      FileUtils.mkdir_p(File.expand_path("data/integrations/shopify/2023-12/mappings", @tmp_base_path))

      command = GenerateReleaseCommand.new(current_version: @version, next_version: @next_version)
      command.send(:create_previous_version_mappings)

      assert true, "Should complete without error"
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
