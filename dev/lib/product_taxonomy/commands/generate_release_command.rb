# frozen_string_literal: true

module ProductTaxonomy
  class GenerateReleaseCommand < Command
    def initialize(options)
      super

      @version = validate_and_sanitize_version!(options[:current_version])
      @next_version = validate_and_sanitize_version!(options[:next_version])

      if @version.end_with?("-unstable")
        raise ArgumentError, "Version must not end with '-unstable' suffix"
      end

      unless @next_version.end_with?("-unstable")
        raise ArgumentError, "Next version must end with '-unstable' suffix"
      end

      @locales = if options[:locales] == ["all"]
        locales_defined_in_data_path
      else
        options[:locales]
      end
    end

    def execute
      check_git_state!

      begin
        logger.info("Generating release for version: #{@version}")
        release_commit_hash = generate_release_version!

        logger.info("Moving to next unstable version: #{@next_version}")
        next_version_commit_hash = move_to_next_version!

        print_summary(release_commit_hash, next_version_commit_hash)
      rescue StandardError
        print_rollback_instructions
        raise
      end
    end

    private

    def check_git_state!
      current_branch = %x(git rev-parse --abbrev-ref HEAD).strip
      unless current_branch == "main"
        raise "Must be on main branch to create a release. Current branch: #{current_branch}"
      end

      status_output = %x(git status --porcelain).strip
      unless status_output.empty?
        raise "Working directory is not clean. Please commit or stash changes before creating a release."
      end
    end

    def release_commit_message = "Release version #{@version} [run-ci]"
    def next_version_commit_message = "Bump version to #{@next_version} [run-ci]"

    def generate_release_version!
      run_git_command("pull")
      run_git_command("checkout", "-b", "release-v#{@version}")

      logger.info("Updating VERSION file to #{@version}...")
      File.write(version_file_path, @version)

      logger.info("Updating integration mappings...")
      update_integration_mappings_stable_release

      logger.info("Dumping integration full names...")
      DumpIntegrationFullNamesCommand.new({}).execute

      logger.info("Generating distribution files...")
      GenerateDistCommand.new(version: @version, locales: @locales).execute

      logger.info("Generating documentation files...")
      GenerateDocsCommand.new(version: @version, locales: @locales).execute

      logger.info("Updating README.md files...")
      update_version_badge(File.expand_path("../README.md", ProductTaxonomy.data_path))
      update_version_badge(File.expand_path("../dist/README.md", ProductTaxonomy.data_path))

      logger.info("Committing and tagging release version #{@version}...")
      run_git_command("add", ".")
      run_git_command("commit", "-m", release_commit_message)
      run_git_command("tag", "v#{@version}")

      get_commit_hash("HEAD")
    end

    def move_to_next_version!
      run_git_command("checkout", "-b", "bump-v#{@next_version}")

      logger.info("Updating VERSION file to #{@next_version}...")
      File.write(version_file_path, @next_version)

      logger.info("Updating integration mappings...")
      update_integration_mappings_next_unstable

      logger.info("Generating distribution files...")
      GenerateDistCommand.new(version: @next_version, locales: @locales).execute

      logger.info("Generating documentation files...")
      GenerateDocsCommand.new(locales: @locales).execute

      run_git_command("add", ".")
      run_git_command("commit", "-m", next_version_commit_message)

      get_commit_hash("HEAD")
    end

    def run_git_command(*args)
      result = system("git", *args, chdir: git_repo_root)

      raise "Git command failed." unless result
    end

    def git_repo_root
      @git_repo_root ||= %x(git rev-parse --show-toplevel).strip
    end

    def get_commit_hash(ref)
      %x(git rev-parse --short #{ref}).strip
    end

    def update_integration_mappings_stable_release
      create_previous_version_mappings
      update_mapping_files("to_shopify.yml", "output_taxonomy", "shopify/#{@version}")
      update_mapping_files("from_shopify.yml", "input_taxonomy", "shopify/#{@version}")
    end

    def update_integration_mappings_next_unstable
      update_mapping_files("from_shopify.yml", "input_taxonomy", "shopify/#{@next_version}")
    end

    def create_previous_version_mappings
      shopify_dir = File.expand_path("integrations/shopify", ProductTaxonomy.data_path)
      
      version_dirs = Dir.glob(File.join(shopify_dir, "*")).select { |d| File.directory?(d) }
        .select { |d| File.basename(d).match?(/^\d{4}-\d{2}$/) }
        .sort

      # Find the latest version without a mappings directory (should be the most recent)
      previous_version_dir = version_dirs.reverse.find do |dir|
        !File.exist?(File.join(dir, "mappings"))
      end

      return unless previous_version_dir

      previous_version = File.basename(previous_version_dir)
      mappings_dir = File.join(previous_version_dir, "mappings")

      FileUtils.mkdir_p(mappings_dir)

      to_shopify_file = File.join(mappings_dir, "to_shopify.yml")
      File.write(to_shopify_file, <<~YAML)
        ---
        input_taxonomy: shopify/#{previous_version}
        output_taxonomy: shopify/#{@version}
        rules: []
      YAML
    end

    def update_mapping_files(filename, field_name, new_value)
      Dir.glob(File.expand_path("integrations/**/mappings/#{filename}", ProductTaxonomy.data_path)).each do |file|
        next if file.match?(%r{/integrations/shopify/\d{4}-\d{2}/})
        
        content = File.read(file)
        content.gsub!(%r{#{field_name}: shopify/\d{4}-\d{2}(-unstable)?}, "#{field_name}: #{new_value}")
        File.write(file, content)
      end
    end

    def update_version_badge(readme_path)
      content = File.read(readme_path)
      content.gsub!(%r{badge/Version-.*?-blue\.svg}) do
        badge_version = @version.gsub("-", "--")
        "badge/Version-#{badge_version}-blue.svg"
      end
      File.write(readme_path, content)
    end

    def print_summary(release_commit_hash, next_version_commit_hash)
      logger.info("\n====== Release Summary ======")
      logger.info("- Created branch: release-v#{@version}")
      logger.info("  - Commit (#{release_commit_hash}): #{release_commit_message}")
      logger.info("  - Tag: v#{@version}")
      logger.info("- Created branch: bump-v#{@next_version}")
      logger.info("  - Commit (#{next_version_commit_hash}): #{next_version_commit_message}")
      logger.info("\nInspect changes with:")
      logger.info("  git show #{release_commit_hash}")
      logger.info("  git show #{next_version_commit_hash}")
      logger.info("  git show v#{@version}")

      logger.info("\nNext steps:")
      logger.info("  1. If the changes look good, push both branches")
      logger.info("     * Run `git push origin release-v#{@version}`")
      logger.info("     * Run `git push origin bump-v#{@next_version}`")
      logger.info("  2. Open a PR and follow the usual process to get approval and merge the release branch")
      logger.info("     * https://github.com/Shopify/product-taxonomy/pull/new/release-v#{@version}")
      logger.info("     * Target: main")
      logger.info("  3. Open a PR and follow the usual process to get approval and merge the bump branch")
      logger.info("     * https://github.com/Shopify/product-taxonomy/pull/new/bump-v#{@next_version}")
      logger.info("     * Target: release-v#{@version} (NOT main)")
      logger.info("     * This PR should be set to merge into release-v#{@version}")
      logger.info("  4. Merge PRs in order")
      logger.info("     * First: Merge the release PR into main")
      logger.info("     * Second: Update the bump PR to target main, then merge")
      logger.info("  5. Once the PRs are merged, push the tag that was created")
      logger.info("     * Run `git push origin v#{@version}`")
      logger.info("  6. Create a release on GitHub")
      logger.info("     * https://github.com/Shopify/product-taxonomy/releases/new?tag=v#{@version}")
    end

    def print_rollback_instructions
      logger.info("\n====== Rollback Instructions ======")
      logger.info("The release was aborted due to an error.")
      logger.info("You can use the following commands to roll back to the original state:")
      logger.info("  git checkout main")
      logger.info("  git reset --hard origin/main")

      # Check if branches exist before suggesting deletion
      if system("git", "show-ref", "--verify", "--quiet", "refs/heads/release-v#{@version}")
        logger.info("  git branch -D release-v#{@version}")
      end

      if system("git", "show-ref", "--verify", "--quiet", "refs/heads/bump-v#{@next_version}")
        logger.info("  git branch -D bump-v#{@next_version}")
      end

      # Check if tag exists before suggesting deletion
      if system("git", "show-ref", "--verify", "--quiet", "refs/tags/v#{@version}")
        logger.info("  git tag -d v#{@version}")
      end
    end
  end
end
