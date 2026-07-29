# frozen_string_literal: true

require "json"

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

    def initialize(
      options,
      command_runner: CommandExecutor::DEFAULT_RUNNER,
      stager_class: DistAssetStager,
      publisher_class: ReleaseAssetPublisher,
      workspace_class: TaggedReleaseWorkspace
    )
      super(options)

      @tags = Array(options[:tags]).map(&:to_s)
      @tags.each { validate_stable_tag!(_1) }
      @dry_run = options.fetch(:dry_run, false)
      @command_executor = CommandExecutor.new(command_runner:)
      @stager_class = stager_class
      @publisher = publisher_class.new(command_executor: @command_executor)
      @workspace_class = workspace_class
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
      output = @command_executor.run!(
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
      staged_file_count = workspace(repository_root, tag).with_paths do |source_path, staging_path|
        resolve_lfs_files!(source_path, tag)

        staged_files = @stager_class.new(
          input_path: File.join(source_path, "dist"),
          output_path: staging_path,
        ).stage
        raise "No release assets were staged for #{tag}." if staged_files.empty?

        publish_or_validate!(repository_root, tag, staged_files)
        staged_files.length
      end

      action = @dry_run ? "Staged and validated" : "Published and verified"
      logger.info("#{action} #{staged_file_count} historical assets for #{tag}")
      staged_file_count
    end

    def publish_or_validate!(repository_root, tag, staged_files)
      arguments = { repository_root:, tag:, staged_files: }
      return @publisher.validate!(**arguments) if @dry_run

      @publisher.publish!(
        **arguments,
        retry_command: "bin/product_taxonomy backfill_release_assets --tags #{tag}",
      )
    end

    def workspace(repository_root, tag)
      @workspace_class.new(
        repository_root:,
        tag:,
        command_executor: @command_executor,
        logger:,
        temporary_prefix: "product-taxonomy-backfill-#{tag}-",
      )
    end

    def resolve_lfs_files!(source_path, tag)
      @command_executor.run!(
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
      _, _, status = @command_executor.capture(
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
      output = @command_executor.run!(
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

    def validate_stable_tag!(tag)
      return if tag.match?(STABLE_TAG_PATTERN)

      raise ArgumentError, "Tags must be exact stable tags such as v2024-01"
    end

    def repository_root!
      @command_executor.run!(
        "git",
        "rev-parse",
        "--show-toplevel",
        chdir: Dir.pwd,
        failure_message: "Could not determine the Git repository root.",
      ).strip
    end
  end
end
