# frozen_string_literal: true

module ProductTaxonomy
  class ReleaseAssetPublisher
    class ExistingAssetsError < RuntimeError; end

    def initialize(command_executor:)
      @command_executor = command_executor
    end

    def validate!(repository_root:, tag:, staged_files:)
      existing_asset_output = @command_executor.run!(
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
      existing_asset_names = names_from(existing_asset_output)
      conflicting_asset_names = expected_names(staged_files) & existing_asset_names
      return if conflicting_asset_names.empty?

      raise ExistingAssetsError,
        "GitHub release #{tag} already contains expected assets: #{conflicting_asset_names.join(", ")}. " \
          "Refusing to overwrite existing assets."
    end

    def publish!(repository_root:, tag:, staged_files:, retry_command:)
      validate!(repository_root:, tag:, staged_files:)

      begin
        @command_executor.run!(
          "gh",
          "release",
          "upload",
          tag,
          *staged_files,
          chdir: repository_root,
          failure_message: "Asset upload failed for GitHub release #{tag}.",
        )
        verify!(repository_root:, tag:, staged_files:)
      rescue StandardError => error
        raise "#{error.message}\n\n#{partial_upload_retry_instructions(tag, retry_command)}"
      end
    end

    private

    def verify!(repository_root:, tag:, staged_files:)
      uploaded_asset_output = @command_executor.run!(
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
      missing_asset_names = expected_names(staged_files) - names_from(uploaded_asset_output)
      return if missing_asset_names.empty?

      raise "GitHub release #{tag} is missing uploaded assets: #{missing_asset_names.join(", ")}"
    end

    def expected_names(staged_files)
      staged_files.map { File.basename(_1) }.sort
    end

    def names_from(output)
      output.lines.map(&:strip).reject(&:empty?)
    end

    def partial_upload_retry_instructions(tag, retry_command)
      <<~INSTRUCTIONS.chomp
        Asset publication may have partially succeeded. Before retrying:
          1. Inspect assets already present on the release:
             gh release view #{tag} --json assets --jq '.assets[].name'
          2. Delete each asset uploaded by this failed attempt:
             gh release delete-asset #{tag} <asset-name> --yes
          3. Rerun publication:
             #{retry_command}
      INSTRUCTIONS
    end
  end
end
