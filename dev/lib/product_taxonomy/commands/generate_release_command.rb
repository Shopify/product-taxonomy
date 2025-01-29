# frozen_string_literal: true

module ProductTaxonomy
  class GenerateReleaseCommand < Command
    def initialize(options)
      super

      @version = options[:version] || File.read(version_file_path).strip
      @locales = if options[:locales] == ["all"]
        locales_defined_in_data_path
      else
        options[:locales]
      end
    end

    def execute
      logger.info("Generating release for version: #{@version}")

      logger.info("Generating distribution files...")
      GenerateDistCommand.new(version: @version, locales: @locales).execute

      logger.info("Generating documentation files...")
      GenerateDocsCommand.new(version: @version, locales: @locales).execute

      logger.info("Updating VERSION file...")
      File.write(version_file_path, @version)

      logger.info("Creating git tag...")
      system("git", "tag", "v#{@version}")

      logger.info("Updating README.md...")
      update_readme
    end

    private

    def update_readme
      readme_path = File.expand_path("../dist/README.md", ProductTaxonomy.data_path)
      content = File.read(readme_path)
      content.gsub!(%r{badge/Version-.*?-blue\.svg}) do
        badge_version = @version.gsub("-", "--")
        "badge/Version-#{badge_version}-blue.svg"
      end
      File.write(readme_path, content)
    end
  end
end
