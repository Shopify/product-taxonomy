# frozen_string_literal: true

module ProductTaxonomy
  class PublishReleaseAssetsCommand < Command
    STABLE_TAG_PATTERN = /\Av(\d{4}-\d{2})\z/

    def initialize(
      options,
      command_runner: CommandExecutor::DEFAULT_RUNNER,
      stager_class: DistAssetStager,
      publisher_class: ReleaseAssetPublisher,
      workspace_class: TaggedReleaseWorkspace
    )
      super(options)

      @tag = options.fetch(:tag)
      tag_match = STABLE_TAG_PATTERN.match(@tag)
      raise ArgumentError, "Tag must be an exact stable tag such as v2024-01" unless tag_match

      @version = tag_match[1]
      @command_executor = CommandExecutor.new(command_runner:)
      @stager_class = stager_class
      @publisher = publisher_class.new(command_executor: @command_executor)
      @workspace_class = workspace_class
    end

    def execute
      repository_root = repository_root!
      ensure_tag_exists!(repository_root)
      ensure_release_exists!(repository_root)

      staged_file_count = workspace(repository_root).with_paths do |source_path, staging_path|
        @command_executor.run!(
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

        @publisher.publish!(
          repository_root:,
          tag: @tag,
          staged_files:,
          retry_command: "bin/product_taxonomy publish_release_assets #{@tag}",
        )
        staged_files.length
      end

      logger.info("Published and verified #{staged_file_count} assets for #{@tag}")
    end

    private

    def workspace(repository_root)
      @workspace_class.new(
        repository_root:,
        tag: @tag,
        command_executor: @command_executor,
        logger:,
        temporary_prefix: "product-taxonomy-release-#{@tag}-",
      )
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

    def ensure_tag_exists!(repository_root)
      _, _, status = @command_executor.capture(
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
      @command_executor.run!(
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
  end
end
