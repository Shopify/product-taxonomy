# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class PublishReleaseAssetsCommandTest < TestCase
    FakeStatus = Data.define(:success?)
    RecordedCall = Data.define(:command, :chdir)

    class FakeCommandRunner
      attr_accessor(
        :tag_exists,
        :release_exists,
        :dist_succeeds,
        :upload_succeeds,
        :uploaded_asset_names,
        :worktree_remove_succeeds,
      )
      attr_reader :calls

      def initialize(repository_root)
        @repository_root = repository_root
        @tag_exists = true
        @release_exists = true
        @dist_succeeds = true
        @upload_succeeds = true
        @uploaded_asset_names = RecordingStager.asset_names
        @worktree_remove_succeeds = true
        @calls = []
      end

      def call(*command, chdir:)
        @calls << RecordedCall.new(command:, chdir:)

        case command
        when ["git", "rev-parse", "--show-toplevel"]
          success("#{@repository_root}\n")
        when ["git", "rev-parse", "--verify", "--quiet", "refs/tags/v2024-01^{commit}"]
          result(@tag_exists, stderr: "unknown revision")
        when ["gh", "release", "view", "v2024-01", "--json", "tagName"]
          result(@release_exists, stdout: "{\"tagName\":\"v2024-01\"}\n", stderr: "release not found")
        when ["bin/product_taxonomy", "dist", "--version", "2024-01", "--locales", "all"]
          result(@dist_succeeds, stderr: "generator exploded")
        when [
          "gh",
          "release",
          "view",
          "v2024-01",
          "--json",
          "assets",
          "--jq",
          ".assets[] | select(.state == \"uploaded\") | .name",
        ]
          success(@uploaded_asset_names.join("\n") + "\n")
        else
          return success if worktree_add_command?(command)
          return result(@worktree_remove_succeeds, stderr: "cleanup failed") if worktree_remove_command?(command)
          return result(@upload_succeeds, stderr: "HTTP 500") if upload_command?(command)

          raise "Unexpected command: #{command.inspect}"
        end
      end

      private

      def worktree_add_command?(command)
        command.first(3) == ["git", "worktree", "add"]
      end

      def worktree_remove_command?(command)
        command.first(4) == ["git", "worktree", "remove", "--force"]
      end

      def upload_command?(command)
        command.first(4) == ["gh", "release", "upload", "v2024-01"]
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
        attr_accessor :asset_names, :initializations, :stage_count, :stage_error

        def reset
          self.asset_names = ["categories.en.json.gz", "integrations.all_mappings.en.json.gz"]
          self.initializations = []
          self.stage_count = 0
          self.stage_error = nil
        end
      end

      def initialize(input_path:, output_path:)
        @output_path = output_path
        self.class.initializations << { input_path:, output_path: }
      end

      def stage
        self.class.stage_count += 1
        raise self.class.stage_error if self.class.stage_error

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
      File.write(File.join(@repository_root, "VERSION"), "2099-12-unstable")
      RecordingStager.reset
      @command_runner = FakeCommandRunner.new(@repository_root)
    end

    teardown do
      FileUtils.remove_entry(@repository_root)
    end

    test "#initialize rejects an unstable tag" do
      error = assert_raises(ArgumentError) do
        build_command(tag: "v2024-01-unstable")
      end

      assert_equal("Tag must be an exact stable tag such as v2024-01", error.message)
    end

    test "#execute generates from the exact tag and publishes staged assets before verifying them" do
      build_command.execute

      worktree_call = recorded_call_starting_with("git", "worktree", "add")
      assert_equal("v2024-01", worktree_call.command.last)

      dist_call = recorded_call_starting_with("bin/product_taxonomy", "dist")
      assert_equal(
        ["bin/product_taxonomy", "dist", "--version", "2024-01", "--locales", "all"],
        dist_call.command,
      )
      assert_match(%r{/source/dev\z}, dist_call.chdir)

      assert_equal(1, RecordingStager.stage_count)
      assert_equal(1, RecordingStager.initializations.length)
      assert_match(%r{/source/dist\z}, RecordingStager.initializations.first.fetch(:input_path))

      upload_call = recorded_call_starting_with("gh", "release", "upload")
      assert_equal(["gh", "release", "upload", "v2024-01"], upload_call.command.first(4))
      assert_equal(RecordingStager.asset_names, upload_call.command.drop(4).map { File.basename(_1) })
      refute_includes(upload_call.command, "--clobber")

      upload_index = @command_runner.calls.index(upload_call)
      verification_index = @command_runner.calls.index do |call|
        call.command == [
          "gh",
          "release",
          "view",
          "v2024-01",
          "--json",
          "assets",
          "--jq",
          ".assets[] | select(.state == \"uploaded\") | .name",
        ]
      end
      assert_operator(verification_index, :>, upload_index)
    end

    test "#execute raises before generation when the tag does not exist" do
      @command_runner.tag_exists = false

      error = assert_raises(RuntimeError) { build_command.execute }

      assert_equal("Tag v2024-01 does not exist.", error.message)
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "view"] })
    end

    test "#execute raises before generation when the GitHub release does not exist" do
      @command_runner.release_exists = false

      error = assert_raises(RuntimeError) { build_command.execute }

      assert_equal(
        "GitHub release v2024-01 does not exist or is inaccessible. release not found",
        error.message,
      )
      refute(@command_runner.calls.any? { _1.command.first(2) == ["bin/product_taxonomy", "dist"] })
    end

    test "#execute raises with generation output when tagged distribution generation fails" do
      @command_runner.dist_succeeds = false

      error = assert_raises(RuntimeError) { build_command.execute }

      assert_equal("Distribution generation failed for v2024-01. generator exploded", error.message)
      assert_instance_of(RecordedCall, recorded_call_starting_with("git", "worktree", "remove"))
    end

    test "#execute preserves the generation failure and recommends pruning when worktree cleanup also fails" do
      @command_runner.dist_succeeds = false
      @command_runner.worktree_remove_succeeds = false
      error = nil

      stdout, = capture_io do
        error = assert_raises(RuntimeError) { build_command(quiet: false).execute }
      end

      assert_equal("Distribution generation failed for v2024-01. generator exploded", error.message)
      assert_includes(stdout, "git worktree prune")
      refute_includes(stdout, "git worktree remove --force")
      assert_instance_of(RecordedCall, recorded_call_starting_with("git", "worktree", "remove"))
    end

    test "#execute raises before upload when no release assets are staged" do
      RecordingStager.asset_names = []

      error = assert_raises(RuntimeError) { build_command.execute }

      assert_equal("No release assets were staged for v2024-01.", error.message)
      refute(@command_runner.calls.any? { _1.command.first(3) == ["gh", "release", "upload"] })
      assert_instance_of(RecordedCall, recorded_call_starting_with("git", "worktree", "remove"))
    end

    test "#execute propagates staging failures and removes the temporary worktree" do
      RecordingStager.stage_error = ArgumentError.new("naming collision")

      error = assert_raises(ArgumentError) { build_command.execute }

      assert_equal("naming collision", error.message)
      assert_instance_of(RecordedCall, recorded_call_starting_with("git", "worktree", "remove"))
    end

    test "#execute prints partial-upload retry instructions when GitHub rejects an asset" do
      @command_runner.upload_succeeds = false

      error = assert_raises(RuntimeError) { build_command.execute }

      assert_includes(error.message, "Asset upload failed for GitHub release v2024-01. HTTP 500")
      assert_retry_instructions(error)
      assert_instance_of(RecordedCall, recorded_call_starting_with("git", "worktree", "remove"))
    end

    test "#execute prints partial-upload retry instructions when uploaded assets cannot be verified" do
      @command_runner.uploaded_asset_names = ["categories.en.json.gz"]

      error = assert_raises(RuntimeError) { build_command.execute }

      assert_includes(
        error.message,
        "GitHub release v2024-01 is missing uploaded assets: integrations.all_mappings.en.json.gz",
      )
      assert_retry_instructions(error)
    end

    private

    def build_command(tag: "v2024-01", quiet: true)
      PublishReleaseAssetsCommand.new(
        { tag:, quiet: },
        command_runner: @command_runner,
        stager_class: RecordingStager,
      )
    end

    def recorded_call_starting_with(*command_prefix)
      @command_runner.calls.find { _1.command.first(command_prefix.length) == command_prefix }
    end

    def assert_retry_instructions(error)
      assert_includes(error.message, "gh release view v2024-01 --json assets --jq '.assets[].name'")
      assert_includes(error.message, "gh release delete-asset v2024-01 <asset-name> --yes")
      assert_includes(error.message, "bin/product_taxonomy publish_release_assets v2024-01")
    end
  end
end
