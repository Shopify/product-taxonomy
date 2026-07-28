# frozen_string_literal: true

require "json"
require "open3"
require "tmpdir"

module ProductTaxonomy
  class BackfillReleaseAssetsCommand < Command
    STABLE_TAG_PATTERN = /\Av\d{4}-\d{2}\z/
    LFS_POINTER_HEADER = "version https://git-lfs.github.com/spec/v1"
    LFS_FILTER_CONFIG = [
      "-c",
      "filter.lfs.process=git-lfs filter-process",
      "-c",
      "filter.lfs.smudge=git-lfs smudge -- %f",
      "-c",
      "filter.lfs.clean=git-lfs clean -- %f",
      "-c",
      "filter.lfs.required=true",
    ].freeze
    RELEASE_LIST_LIMIT = 1_000

    def initialize(options, command_runner: Open3.method(:capture3), stager_class: DistAssetStager)
      super(options)

      @tags = Array(options[:tags]).map(&:to_s)
      @tags.each { validate_stable_tag!(_1) }
      @dry_run = options.fetch(:dry_run, false)
      @command_runner = command_runner
      @stager_class = stager_class
    end

    def execute
      repository_root = repository_root!
      tags = selected_tags(repository_root)
      raise "No stable GitHub releases were found to backfill." if tags.empty?

      validate_releases!(repository_root, tags)

      total_asset_count = tags.sum { backfill_release(repository_root, _1) }
      action = @dry_run ? "Staged and validated" : "Published and verified"
      logger.info("#{action} #{total_asset_count} assets across #{tags.length} stable releases")
    end

    private

    def selected_tags(repository_root)
      tags = @tags.empty? ? discover_stable_release_tags(repository_root) : @tags
      tags.uniq.sort
    end

    def discover_stable_release_tags(repository_root)
      output = run_command!(
        "gh",
        "release",
        "list",
        "--limit",
        RELEASE_LIST_LIMIT.to_s,
        "--json",
        "tagName,isDraft,isPrerelease",
        chdir: repository_root,
        failure_message: "Could not list GitHub releases.",
      )
      releases = JSON.parse(output)

      releases.filter_map do |release|
        next if release.fetch("isDraft") || release.fetch("isPrerelease")

        tag = release.fetch("tagName")
        tag if tag.match?(STABLE_TAG_PATTERN)
      end
    rescue JSON::ParserError, KeyError => error
      raise "Could not parse GitHub releases: #{error.message}"
    end

    def validate_releases!(repository_root, tags)
      tags.each { ensure_tag_exists!(repository_root, _1) }
      tags.each { ensure_stable_release_exists!(repository_root, _1) }
    end

    def backfill_release(repository_root, tag)
      staged_file_count = Dir.mktmpdir("product-taxonomy-backfill-#{tag}-") do |temporary_directory|
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
            tag,
            chdir: repository_root,
            failure_message: "Could not create a worktree for #{tag}.",
          )
          worktree_created = true

          resolve_lfs_files!(source_path, tag)

          staged_files = @stager_class.new(
            input_path: File.join(source_path, "dist"),
            output_path: staging_path,
          ).stage
          raise "No release assets were staged for #{tag}." if staged_files.empty?

          ensure_no_asset_conflicts!(repository_root, tag, staged_files)
          publish_and_verify!(repository_root, tag, staged_files) unless @dry_run
          staged_files.length
        ensure
          remove_worktree(repository_root, source_path, tag) if worktree_created
        end
      end

      action = @dry_run ? "Staged and validated" : "Published and verified"
      logger.info("#{action} #{staged_file_count} historical assets for #{tag}")
      staged_file_count
    end

    def resolve_lfs_files!(source_path, tag)
      run_command!(
        "git",
        *LFS_FILTER_CONFIG,
        "lfs",
        "pull",
        "--include=dist/**",
        "--exclude=",
        chdir: source_path,
        failure_message: "Could not resolve Git LFS files for #{tag}.",
      )

      unresolved_paths = unresolved_lfs_pointer_paths(File.join(source_path, "dist"))
      return if unresolved_paths.empty?

      raise "Git LFS pointers remain unresolved for #{tag}: #{unresolved_paths.join(", ")}"
    end

    def unresolved_lfs_pointer_paths(dist_path)
      Dir.glob(File.join(dist_path, "**", "*")).select { File.file?(_1) }.filter_map do |path|
        first_line = File.open(path, "rb", &:gets)&.strip
        path.delete_prefix("#{dist_path}#{File::SEPARATOR}") if first_line == LFS_POINTER_HEADER
      end.sort
    end

    def ensure_tag_exists!(repository_root, tag)
      _, _, status = capture_command(
        "git",
        "rev-parse",
        "--verify",
        "--quiet",
        "refs/tags/#{tag}^{commit}",
        chdir: repository_root,
        failure_message: "Could not check whether tag #{tag} exists.",
      )
      raise "Tag #{tag} does not exist locally. Fetch tags and retry." unless status.success?
    end

    def ensure_stable_release_exists!(repository_root, tag)
      output = run_command!(
        "gh",
        "release",
        "view",
        tag,
        "--json",
        "tagName,isDraft,isPrerelease",
        chdir: repository_root,
        failure_message: "GitHub release #{tag} does not exist or is inaccessible.",
      )
      release = JSON.parse(output)
      return unless release.fetch("isDraft") || release.fetch("isPrerelease")

      raise "GitHub release #{tag} is not a published stable release."
    rescue JSON::ParserError, KeyError => error
      raise "Could not parse GitHub release #{tag}: #{error.message}"
    end

    def ensure_no_asset_conflicts!(repository_root, tag, staged_files)
      existing_asset_output = run_command!(
        "gh",
        "release",
        "view",
        tag,
        "--json",
        "assets",
        "--jq",
        ".assets[].name",
        chdir: repository_root,
        failure_message: "Could not inspect existing assets on GitHub release #{tag}.",
      )
      existing_asset_names = existing_asset_output.lines.map(&:strip).reject(&:empty?)
      expected_asset_names = staged_files.map { File.basename(_1) }.sort
      conflicting_asset_names = expected_asset_names & existing_asset_names
      return if conflicting_asset_names.empty?

      raise "GitHub release #{tag} already contains expected assets: #{conflicting_asset_names.join(", ")}. " \
        "Refusing to overwrite existing assets."
    end

    def publish_and_verify!(repository_root, tag, staged_files)
      run_command!(
        "gh",
        "release",
        "upload",
        tag,
        *staged_files,
        chdir: repository_root,
        failure_message: "Asset upload failed for GitHub release #{tag}.",
      )
      verify_assets!(repository_root, tag, staged_files)
    rescue StandardError => error
      raise "#{error.message}\n\n#{partial_upload_retry_instructions(tag)}"
    end

    def verify_assets!(repository_root, tag, staged_files)
      uploaded_asset_output = run_command!(
        "gh",
        "release",
        "view",
        tag,
        "--json",
        "assets",
        "--jq",
        ".assets[] | select(.state == \"uploaded\") | .name",
        chdir: repository_root,
        failure_message: "Could not verify assets on GitHub release #{tag}.",
      )
      uploaded_asset_names = uploaded_asset_output.lines.map(&:strip).reject(&:empty?)
      expected_asset_names = staged_files.map { File.basename(_1) }.sort
      missing_asset_names = expected_asset_names - uploaded_asset_names
      return if missing_asset_names.empty?

      raise "GitHub release #{tag} is missing uploaded assets: #{missing_asset_names.join(", ")}"
    end

    def partial_upload_retry_instructions(tag)
      <<~INSTRUCTIONS.chomp
        Asset backfill may have partially succeeded. Before retrying:
          1. Inspect assets already present on the release:
             gh release view #{tag} --json assets --jq '.assets[].name'
          2. Delete each asset uploaded by this failed attempt:
             gh release delete-asset #{tag} <asset-name> --yes
          3. Rerun the backfill for only this release:
             bin/product_taxonomy backfill_release_assets --tags #{tag}
      INSTRUCTIONS
    end

    def remove_worktree(repository_root, source_path, tag)
      run_command!(
        "git",
        "worktree",
        "remove",
        "--force",
        source_path,
        chdir: repository_root,
        failure_message: "Could not remove temporary worktree for #{tag}.",
      )
    rescue StandardError => cleanup_error
      logger.warn(
        "Could not remove temporary worktree at #{source_path}: #{cleanup_error.message}. " \
          "Run `git worktree prune` from #{repository_root} after this command exits.",
      )
    end

    def validate_stable_tag!(tag)
      return if tag.match?(STABLE_TAG_PATTERN)

      raise ArgumentError, "Tags must be exact stable tags such as v2024-01"
    end

    def repository_root!
      run_command!(
        "git",
        "rev-parse",
        "--show-toplevel",
        chdir: Dir.pwd,
        failure_message: "Could not determine the Git repository root.",
      ).strip
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
