# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class BackfillReleaseAssetsCommandTest < TestCase
    FakeStatus = Data.define(:success?)
    RecordedCall = Data.define(:command, :chdir)

    class FakeCommandRunner
      attr_accessor(
        :annotated_remote_tags,
        :existing_asset_names,
        :lfs_pull_succeeds,
        :local_tag_commits,
        :missing_release_tags,
        :missing_remote_tags,
        :missing_tags,
        :release_list,
        :remote_tag_commits,
        :upload_failure_tags,
        :upload_succeeds,
        :uploaded_asset_names,
        :worktree_remove_succeeds,
        :write_unresolved_pointer,
      )
      attr_reader :calls

      def initialize(repository_root)
        @repository_root = repository_root
        @annotated_remote_tags = ["v2024-10"]
        @existing_asset_names = []
        @lfs_pull_succeeds = true
        @local_tag_commits = Hash.new { |_, tag| "commit-for-#{tag}" }
        @missing_release_tags = []
        @missing_remote_tags = []
        @missing_tags = []
        @release_list = [
          { "tagName" => "v2024-10-beta1", "isDraft" => false, "isPrerelease" => true },
          { "tagName" => "v2024-10", "isDraft" => false, "isPrerelease" => false },
          { "tagName" => "v2024-07", "isDraft" => false, "isPrerelease" => false },
          { "tagName" => "unstable", "isDraft" => false, "isPrerelease" => true },
          { "tagName" => "v2025-03", "isDraft" => true, "isPrerelease" => false },
        ]
        @remote_tag_commits = Hash.new { |_, tag| "commit-for-#{tag}" }
        @upload_failure_tags = []
        @upload_succeeds = true
        @uploaded_asset_names = RecordingStager.asset_names
        @worktree_remove_succeeds = true
        @write_unresolved_pointer = false
        @calls = []
      end

      def call(*command, chdir:)
        @calls << RecordedCall.new(command:, chdir:)

        case command
        when ["git", "rev-parse", "--show-toplevel"]
          success("#{@repository_root}\n")
        when ["gh", "release", "list", "--limit", "1000", "--json", "tagName,isDraft,isPrerelease"]
          success(JSON.generate(@release_list))
        else
          handle_dynamic_command(command)
        end
      end

      private

      def handle_dynamic_command(command)
        return tag_verification_result(command) if tag_verification_command?(command)
        return remote_tag_verification_result(command) if remote_tag_verification_command?(command)
        return release_view_result(command) if release_view_command?(command)
        return create_worktree(command) if worktree_add_command?(command)
        return result(@lfs_pull_succeeds, stderr: "LFS download failed") if lfs_pull_command?(command)
        return result(@worktree_remove_succeeds, stderr: "cleanup failed") if worktree_remove_command?(command)
        return upload_result(command) if upload_command?(command)
        return success(@existing_asset_names.join("\n") + "\n") if asset_preflight_command?(command)
        return success(@uploaded_asset_names.join("\n") + "\n") if asset_verification_command?(command)

        raise "Unexpected command: #{command.inspect}"
      end

      def tag_verification_command?(command)
        command.first(4) == ["git", "rev-parse", "--verify", "--quiet"]
      end

      def tag_verification_result(command)
        tag = command.fetch(4)[%r{\Arefs/tags/(.+)\^\{commit\}\z}, 1]
        result(
          !@missing_tags.include?(tag),
          stdout: "#{@local_tag_commits[tag]}\n",
          stderr: "unknown revision",
        )
      end

      def remote_tag_verification_command?(command)
        command.first(4) == ["git", "ls-remote", "--exit-code", "origin"]
      end

      def remote_tag_verification_result(command)
        tag_ref = command.fetch(4)
        tag = tag_ref.delete_prefix("refs/tags/")
        return result(false, stderr: "not found") if @missing_remote_tags.include?(tag)

        commit = @remote_tag_commits[tag]
        output = if @annotated_remote_tags.include?(tag)
          "tag-object-for-#{tag}\t#{tag_ref}\n#{commit}\t#{tag_ref}^{}\n"
        else
          "#{commit}\t#{tag_ref}\n"
        end
        success(output)
      end

      def release_view_command?(command)
        command.first(3) == ["gh", "release", "view"] && command.drop(4) == [
          "--json",
          "tagName,isDraft,isPrerelease",
        ]
      end

      def release_view_result(command)
        tag = command.fetch(3)
        release = @release_list.find { _1.fetch("tagName") == tag } || {
          "tagName" => tag,
          "isDraft" => false,
          "isPrerelease" => false,
        }
        exists = !@missing_release_tags.include?(tag)
        result(exists, stdout: "#{JSON.generate(release)}\n", stderr: "release not found")
      end

      def worktree_add_command?(command)
        command.first(4) == ["git", "worktree", "add", "--detach"]
      end

      def lfs_pull_command?(command)
        command == [
          "git",
          *BackfillReleaseAssetsCommand::LFS_FILTER_CONFIG,
          "lfs",
          "pull",
          "--include=dist/**",
          "--exclude=",
        ]
      end

      def worktree_remove_command?(command)
        command.first(4) == ["git", "worktree", "remove", "--force"]
      end

      def upload_command?(command)
        command.first(3) == ["gh", "release", "upload"]
      end

      def upload_result(command)
        tag = command.fetch(3)
        succeeds = @upload_succeeds && !@upload_failure_tags.include?(tag)
        result(succeeds, stderr: "HTTP 500")
      end

      def asset_preflight_command?(command)
        command.first(3) == ["gh", "release", "view"] && command.drop(4) == [
          "--json",
          "assets",
          "--jq",
          ".assets[].name",
        ]
      end

      def asset_verification_command?(command)
        command.first(3) == ["gh", "release", "view"] && command.drop(4) == [
          "--json",
          "assets",
          "--jq",
          ".assets[] | select(.state == \"uploaded\") | .name",
        ]
      end

      def create_worktree(command)
        if @write_unresolved_pointer
          pointer_path = File.join(command[4], "dist", "en", "taxonomy.json")
          FileUtils.mkdir_p(File.dirname(pointer_path))
          File.write(
            pointer_path,
            "version https://git-lfs.github.com/spec/v1\n" \
              "oid sha256:0123456789abcdef\n" \
              "size 123\n",
          )
        end
        success
      end

      def success(stdout = "")
        result(true, stdout:)
      end

      def result(success, stdout: "", stderr: "")
        [stdout, stderr, FakeStatus.new(success?: success)]
      end
    end

    class RecordingStager
      class << self
        attr_accessor :asset_names, :initializations, :stage_count

        def reset
          self.asset_names = ["categories.en.json.gz", "integrations.all_mappings.en.json.gz"]
          self.initializations = []
          self.stage_count = 0
        end
      end

      def initialize(input_path:, output_path:)
        @output_path = output_path
        self.class.initializations << { input_path:, output_path: }
      end

      def stage
        self.class.stage_count += 1
        FileUtils.mkdir_p(@output_path)
        self.class.asset_names.map do |asset_name|
          path = File.join(@output_path, asset_name)
          File.write(path, "asset")
          path
        end
      end
    end

    setup do
      @repository_root = Dir.mktmpdir
      RecordingStager.reset
      @command_runner = FakeCommandRunner.new(@repository_root)
    end

    teardown do
      FileUtils.remove_entry(@repository_root)
    end

    test "#initialize rejects non-stable explicit tags" do
      error = assert_raises(ArgumentError) do
        build_command(tags: ["v2024-10-beta1"])
      end

      assert_equal("Tags must be exact stable tags such as v2024-01", error.message)
      assert_empty(@command_runner.calls)
    end

    test "#execute discovers non-draft stable releases and processes them oldest first" do
      build_command.execute

      worktree_tags = @command_runner.calls.filter_map do |call|
        call.command.last if call.command.first(4) == ["git", "worktree", "add", "--detach"]
      end
      assert_equal(["v2024-07", "v2024-10"], worktree_tags)
      assert_equal(2, RecordingStager.stage_count)
    end

    test "#execute raises when no stable releases are discovered" do
      @command_runner.release_list = []

      error = assert_raises(RuntimeError) { build_command.execute }

      assert_equal("No stable GitHub releases were found to backfill.", error.message)
      refute(@command_runner.calls.any? { _1.command.first(3) == ["git", "worktree", "add"] })
    end

    test "#execute rejects an explicitly selected draft release" do
      error = assert_raises(RuntimeError) { build_command(tags: ["v2025-03"]).execute }

      assert_equal("GitHub release v2025-03 is not a published stable release.", error.message)
      refute(@command_runner.calls.any? { _1.command.first(3) == ["git", "worktree", "add"] })
    end

    test "#execute rejects an explicitly selected prerelease with a stable-looking tag" do
      @command_runner.release_list << {
        "tagName" => "v2025-06",
        "isDraft" => false,
        "isPrerelease" => true,
      }

      error = assert_raises(RuntimeError) { build_command(tags: ["v2025-06"]).execute }

      assert_equal("GitHub release v2025-06 is not a published stable release.", error.message)
      refute(@command_runner.calls.any? { _1.command.first(3) == ["git", "worktree", "add"] })
    end

    test "#execute extracts committed dist files from the exact tag and resolves LFS before staging" do
      build_command(tags: ["v2024-10"]).execute

      worktree_call = recorded_call_starting_with("git", "worktree", "add", "--detach")
      assert_equal("v2024-10", worktree_call.command.last)

      lfs_call = @command_runner.calls.find { _1.command.include?("lfs") && _1.command.include?("pull") }
      assert_equal(
        [
          "git",
          *BackfillReleaseAssetsCommand::LFS_FILTER_CONFIG,
          "lfs",
          "pull",
          "--include=dist/**",
          "--exclude=",
        ],
        lfs_call.command,
      )
      assert_match(%r{/source\z}, lfs_call.chdir)

      initialization = RecordingStager.initializations.fetch(0)
      assert_match(%r{/source/dist\z}, initialization.fetch(:input_path))
      lfs_index = @command_runner.calls.index(lfs_call)
      upload_index = @command_runner.calls.index(recorded_call_starting_with("gh", "release", "upload"))
      assert_operator(upload_index, :>, lfs_index)
      refute(@command_runner.calls.any? { _1.command.first(2) == ["bin/product_taxonomy", "dist"] })
    end

    test "#execute rejects unresolved LFS pointers using a bounded prefix read" do
      @command_runner.write_unresolved_pointer = true
      File.expects(:binread).with do |path, length|
        path.end_with?("/dist/en/taxonomy.json") && length == BackfillReleaseAssetsCommand::LFS_POINTER_HEADER.bytesize
      end.returns(BackfillReleaseAssetsCommand::LFS_POINTER_HEADER)

      error = assert_raises(RuntimeError) { build_command(tags: ["v2024-10"], dry_run: true).execute }

      assert_equal("Git LFS pointers remain unresolved for v2024-10: en/taxonomy.json", error.message)
      assert_equal(0, RecordingStager.stage_count)
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "upload"] })
      assert_instance_of(RecordedCall, recorded_call_starting_with("git", "worktree", "remove"))
    end

    test "#execute fails clearly and cleans up when LFS resolution fails" do
      @command_runner.lfs_pull_succeeds = false

      error = assert_raises(RuntimeError) { build_command(tags: ["v2024-10"]).execute }

      assert_equal("Could not resolve Git LFS files for v2024-10. LFS download failed", error.message)
      assert_equal(0, RecordingStager.stage_count)
      assert_instance_of(RecordedCall, recorded_call_starting_with("git", "worktree", "remove"))
    end

    test "#execute preserves the LFS failure and recommends pruning when worktree cleanup also fails" do
      @command_runner.lfs_pull_succeeds = false
      @command_runner.worktree_remove_succeeds = false
      error = nil

      stdout, = capture_io do
        error = assert_raises(RuntimeError) { build_command(tags: ["v2024-10"], quiet: false).execute }
      end

      assert_equal("Could not resolve Git LFS files for v2024-10. LFS download failed", error.message)
      assert_includes(stdout, "Could not remove temporary worktree")
      assert_includes(stdout, "git worktree prune")
      assert_instance_of(RecordedCall, recorded_call_starting_with("git", "worktree", "remove"))
    end

    test "#execute dry-run stages, validates, and checks existing assets without uploading" do
      stdout, = capture_io do
        build_command(tags: ["v2024-10"], dry_run: true, quiet: false).execute
      end

      assert_equal(1, RecordingStager.stage_count)
      assert_includes(stdout, "Staged and validated 2 assets across 1 stable releases")
      assert(@command_runner.calls.any? { asset_preflight_call?(_1.command) })
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "upload"] })
      refute(@command_runner.calls.any? { asset_verification_call?(_1.command) })
    end

    test "#execute dry-run rejects existing expected asset names" do
      @command_runner.existing_asset_names = ["categories.en.json.gz"]

      error = assert_raises(RuntimeError) do
        build_command(tags: ["v2024-10"], dry_run: true).execute
      end

      assert_includes(
        error.message,
        "GitHub release v2024-10 already contains expected assets: categories.en.json.gz. " \
          "Refusing to overwrite existing assets.",
      )
      assert_includes(error.message, "If v2024-10 was already backfilled successfully, do not delete its assets")
      assert_includes(error.message, "Rerun with `--tags`")
      assert(@command_runner.calls.any? { asset_preflight_call?(_1.command) })
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "upload"] })
      refute_includes(error.message, "gh release delete-asset")
    end

    test "#execute refuses existing expected asset names without destructive recovery instructions" do
      @command_runner.existing_asset_names = ["categories.en.json.gz"]

      error = assert_raises(RuntimeError) { build_command(tags: ["v2024-10"]).execute }

      assert_includes(error.message, "GitHub release v2024-10 already contains expected assets")
      assert_includes(error.message, "If v2024-10 was already backfilled successfully, do not delete its assets")
      assert_includes(error.message, "containing only releases that still need backfilling")
      refute_includes(error.message, "gh release delete-asset")
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "upload"] })
    end

    test "#execute uploads without clobber and verifies the expected assets" do
      build_command(tags: ["v2024-10"]).execute

      preflight_call = @command_runner.calls.find { asset_preflight_call?(_1.command) }
      upload_call = recorded_call_starting_with("gh", "release", "upload")
      assert_equal(["gh", "release", "upload", "v2024-10"], upload_call.command.first(4))
      assert_equal(RecordingStager.asset_names, upload_call.command.drop(4).map { File.basename(_1) })
      refute_includes(upload_call.command, "--clobber")
      assert_operator(@command_runner.calls.index(preflight_call), :<, @command_runner.calls.index(upload_call))
      assert(@command_runner.calls.any? { asset_verification_call?(_1.command) })
    end

    test "#execute reports missing assets when upload verification is incomplete" do
      @command_runner.uploaded_asset_names = ["categories.en.json.gz"]

      error = assert_raises(RuntimeError) { build_command(tags: ["v2024-10"]).execute }

      assert_includes(
        error.message,
        "GitHub release v2024-10 is missing uploaded assets: integrations.all_mappings.en.json.gz",
      )
      assert_includes(error.message, "bin/product_taxonomy backfill_release_assets --tags v2024-10")
    end

    test "#execute reports release-specific recovery steps after a partial upload" do
      @command_runner.upload_succeeds = false

      error = assert_raises(RuntimeError) { build_command(tags: ["v2024-10"]).execute }

      assert_includes(error.message, "Asset upload failed for GitHub release v2024-10. HTTP 500")
      assert_includes(error.message, "gh release view v2024-10 --json assets --jq '.assets[].name'")
      assert_includes(error.message, "gh release delete-asset v2024-10 <asset-name> --yes")
      assert_includes(error.message, "bin/product_taxonomy backfill_release_assets --tags v2024-10")
    end

    test "#execute retries the failed and remaining tags after an earlier tag was published" do
      @command_runner.upload_failure_tags = ["v2024-10"]
      tags = ["v2024-07", "v2024-10", "v2025-06"]

      error = assert_raises(RuntimeError) { build_command(tags:).execute }

      upload_tags = @command_runner.calls.filter_map do |call|
        call.command.fetch(3) if call.command.first(3) == ["gh", "release", "upload"]
      end
      assert_equal(["v2024-07", "v2024-10"], upload_tags)
      assert_includes(
        error.message,
        "bin/product_taxonomy backfill_release_assets --tags v2024-10 v2025-06",
      )
    end

    test "#execute validates every GitHub release before extracting the first tag" do
      @command_runner.missing_release_tags = ["v2024-10"]

      error = assert_raises(RuntimeError) do
        build_command(tags: ["v2024-07", "v2024-10"]).execute
      end

      assert_equal(
        "GitHub release v2024-10 does not exist or is inaccessible. release not found",
        error.message,
      )
      refute(@command_runner.calls.any? { _1.command.first(3) == ["git", "worktree", "add"] })
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "upload"] })
    end

    test "#execute validates every local tag before extracting the first tag" do
      @command_runner.missing_tags = ["v2024-10"]

      error = assert_raises(RuntimeError) do
        build_command(tags: ["v2024-07", "v2024-10"]).execute
      end

      assert_equal("Tag v2024-10 does not exist locally. Fetch tags and retry.", error.message)
      refute(@command_runner.calls.any? { _1.command.first(3) == ["git", "ls-remote", "--exit-code"] })
      refute(@command_runner.calls.any? { _1.command.first(3) == ["git", "worktree", "add"] })
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "view"] })
    end

    test "#execute rejects a local tag that does not match the canonical remote before mutation" do
      @command_runner.remote_tag_commits["v2024-10"] = "canonical-commit"

      error = assert_raises(RuntimeError) do
        build_command(tags: ["v2024-07", "v2024-10"]).execute
      end

      assert_equal(
        "Local tag v2024-10 resolves to commit-for-v2024-10, but origin resolves to canonical-commit. " \
          "Fetch the canonical tag and retry.",
        error.message,
      )
      assert(@command_runner.calls.any? { _1.command.first(3) == ["git", "ls-remote", "--exit-code"] })
      refute(@command_runner.calls.any? { _1.command.first(3) == ["git", "worktree", "add"] })
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "view"] })
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "upload"] })
    end

    test "#execute rejects a tag missing from the canonical remote before mutation" do
      @command_runner.missing_remote_tags = ["v2024-10"]

      error = assert_raises(RuntimeError) { build_command(tags: ["v2024-10"]).execute }

      assert_equal("Could not resolve tag v2024-10 on origin. not found", error.message)
      refute(@command_runner.calls.any? { _1.command.first(3) == ["git", "worktree", "add"] })
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "view"] })
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "upload"] })
    end

    private

    def build_command(tags: [], dry_run: false, quiet: true)
      BackfillReleaseAssetsCommand.new(
        { tags:, dry_run:, quiet: },
        command_runner: @command_runner,
        stager_class: RecordingStager,
      )
    end

    def recorded_call_starting_with(*command_prefix)
      @command_runner.calls.find { _1.command.first(command_prefix.length) == command_prefix }
    end

    def asset_preflight_call?(command)
      command.first(3) == ["gh", "release", "view"] && command.last == ".assets[].name"
    end

    def asset_verification_call?(command)
      command.first(3) == ["gh", "release", "view"] &&
        command.last == ".assets[] | select(.state == \"uploaded\") | .name"
    end
  end
end
