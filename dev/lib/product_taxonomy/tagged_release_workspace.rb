# frozen_string_literal: true

require "tmpdir"

module ProductTaxonomy
  class TaggedReleaseWorkspace
    def initialize(repository_root:, tag:, command_executor:, logger:, temporary_prefix:)
      @repository_root = repository_root
      @tag = tag
      @command_executor = command_executor
      @logger = logger
      @temporary_prefix = temporary_prefix
    end

    def with_paths
      Dir.mktmpdir(@temporary_prefix) do |temporary_directory|
        source_path = File.join(temporary_directory, "source")
        staging_path = File.join(temporary_directory, "release-assets")
        worktree_created = false

        begin
          @command_executor.run!(
            "git",
            "worktree",
            "add",
            "--detach",
            source_path,
            @tag,
            chdir: @repository_root,
            failure_message: "Could not create a worktree for #{@tag}.",
          )
          worktree_created = true
          yield source_path, staging_path
        ensure
          remove_worktree(source_path) if worktree_created
        end
      end
    end

    private

    def remove_worktree(source_path)
      @command_executor.run!(
        "git",
        "worktree",
        "remove",
        "--force",
        source_path,
        chdir: @repository_root,
        failure_message: "Could not remove temporary worktree for #{@tag}.",
      )
    rescue StandardError => cleanup_error
      @logger.warn(
        "Could not remove temporary worktree at #{source_path}: #{cleanup_error.message}. " \
          "Run `git worktree prune` from #{@repository_root} after this command exits.",
      )
    end
  end
end
