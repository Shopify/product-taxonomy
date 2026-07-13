# frozen_string_literal: true

require "open3"
require "tmpdir"

module ProductTaxonomy
  class PublishReleaseAssetsCommand < Command
    STABLE_TAG_PATTERN = /\Av(\d{4}-\d{2})\z/

    def initialize(options, command_runner: Open3.method(:capture3), stager_class: DistAssetStager)
      super(options)

      @tag = options.fetch(:tag)
      tag_match = STABLE_TAG_PATTERN.match(@tag)
      raise ArgumentError, "Tag must be an exact stable tag such as v2024-01" unless tag_match

      @version = tag_match[1]
      @command_runner = command_runner
      @stager_class = stager_class
    end

    def execute
      repository_root = repository_root!
      ensure_tag_exists!(repository_root)
      ensure_release_exists!(repository_root)

      staged_file_count = Dir.mktmpdir("product-taxonomy-release-") do |temporary_directory|
        source_path = File.join(temporary_directory, "source")
        staging_path = File.join(temporary_directory, "release-assets")
        worktree_created = false

        begin
          run_command!(
            "git",
            "worktree",
            "add",
            "--detach",
            source_path,
            @tag,
            chdir: repository_root,
            failure_message: "Could not create a worktree for #{@tag}.",
          )
          worktree_created = true

          run_command!(
            "bin/product_taxonomy",
            "dist",
            "--version",
            @version,
            "--locales",
            "all",
            chdir: File.join(source_path, "dev"),
            failure_message: "Distribution generation failed for #{@tag}.",
          )

          staged_files = @stager_class.new(
            input_path: File.join(source_path, "dist"),
            output_path: staging_path,
          ).stage
          raise "No release assets were staged for #{@tag}." if staged_files.empty?

          publish_and_verify!(repository_root, staged_files)
          staged_files.length
        ensure
          if worktree_created
            begin
              run_command!(
                "git",
                "worktree",
                "remove",
                "--force",
                source_path,
                chdir: repository_root,
                failure_message: "Could not remove temporary worktree for #{@tag}.",
              )
            rescue StandardError => cleanup_error
              logger.warn(
                "Could not remove temporary worktree at #{source_path}: #{cleanup_error.message}. " \
                  "Run `git worktree prune` from #{repository_root} after this command exits.",
              )
            end
          end
        end
      end

      logger.info("Published and verified #{staged_file_count} assets for #{@tag}")
    end

    private

    def repository_root!
      run_command!(
        "git",
        "rev-parse",
        "--show-toplevel",
        chdir: Dir.pwd,
        failure_message: "Could not determine the Git repository root.",
      ).strip
    end

    def ensure_tag_exists!(repository_root)
      _, _, status = capture_command(
        "git",
        "rev-parse",
        "--verify",
        "--quiet",
        "refs/tags/#{@tag}^{commit}",
        chdir: repository_root,
        failure_message: "Could not check whether tag #{@tag} exists.",
      )
      raise "Tag #{@tag} does not exist." unless status.success?
    end

    def ensure_release_exists!(repository_root)
      run_command!(
        "gh",
        "release",
        "view",
        @tag,
        "--json",
        "tagName",
        chdir: repository_root,
        failure_message: "GitHub release #{@tag} does not exist or is inaccessible.",
      )
    end

    def publish_and_verify!(repository_root, staged_files)
      run_command!(
        "gh",
        "release",
        "upload",
        @tag,
        *staged_files,
        chdir: repository_root,
        failure_message: "Asset upload failed for GitHub release #{@tag}.",
      )
      verify_assets!(repository_root, staged_files)
    rescue StandardError => error
      raise "#{error.message}\n\n#{partial_upload_retry_instructions}"
    end

    def verify_assets!(repository_root, staged_files)
      uploaded_asset_output = run_command!(
        "gh",
        "release",
        "view",
        @tag,
        "--json",
        "assets",
        "--jq",
        ".assets[] | select(.state == \"uploaded\") | .name",
        chdir: repository_root,
        failure_message: "Could not verify assets on GitHub release #{@tag}.",
      )
      uploaded_asset_names = uploaded_asset_output.lines.map(&:strip).reject(&:empty?)
      expected_asset_names = staged_files.map { File.basename(_1) }.sort
      missing_asset_names = expected_asset_names - uploaded_asset_names
      return if missing_asset_names.empty?

      raise "GitHub release #{@tag} is missing uploaded assets: #{missing_asset_names.join(", ")}"
    end

    def partial_upload_retry_instructions
      <<~INSTRUCTIONS.chomp
        Asset publication may have partially succeeded. Before retrying:
          1. Inspect assets already present on the release:
             gh release view #{@tag} --json assets --jq '.assets[].name'
          2. Delete each asset uploaded by this failed attempt:
             gh release delete-asset #{@tag} <asset-name> --yes
          3. Rerun publication:
             bin/product_taxonomy publish_release_assets #{@tag}
      INSTRUCTIONS
    end

    def run_command!(*command, chdir:, failure_message:)
      stdout, stderr, status = capture_command(*command, chdir:, failure_message:)
      return stdout if status.success?

      details = stderr.strip
      details = stdout.strip if details.empty?
      message = details.empty? ? failure_message : "#{failure_message} #{details}"
      raise message
    end

    def capture_command(*command, chdir:, failure_message:)
      @command_runner.call(*command, chdir:)
    rescue SystemCallError => error
      raise "#{failure_message} #{error.message}"
    end
  end
end
