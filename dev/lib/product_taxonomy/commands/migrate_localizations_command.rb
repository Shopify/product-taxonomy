# frozen_string_literal: true

module ProductTaxonomy
  class MigrateLocalizationsCommand < Command
    LOCALIZATION_TYPES = ["categories", "attributes", "values"].freeze

    def initialize(options)
      super
      @dry_run = options[:dry_run] || false
    end

    def execute
      logger.info("Starting localization migration (dry_run: #{@dry_run})")

      localization_files.each do |file_path|
        migrate_file(file_path)
      end

      logger.info("Migration complete!")
    end

    private

    def localization_files
      files = []
      LOCALIZATION_TYPES.each do |type|
        pattern = File.expand_path("localizations/#{type}/*.yml", ProductTaxonomy.data_path)
        files.concat(Dir.glob(pattern))
      end
      # Exclude English files (already migrated)
      files.reject { |f| f.end_with?("/en.yml") }
    end

    def migrate_file(file_path)
      logger.info("Processing #{file_path}...")

      content = YAML.load_file(file_path)
      context_count = 0

      # Navigate the structure: locale -> section -> entries
      locale, sections = content.first
      sections.each do |_section_name, entries|
        next unless entries.is_a?(Hash)

        entries.each do |_entry_id, data|
          if data.is_a?(Hash) && data.key?("context")
            data.delete("context")
            context_count += 1
          end
        end
      end

      if context_count > 0
        logger.info("  Removed #{context_count} context keys")

        unless @dry_run
          # Write back with YAML.dump for consistent formatting
          yaml_output = YAML.dump(content, line_width: -1)

          File.open(file_path, "w") do |file|
            file.puts "# This file is auto-generated. Do not edit directly."
            file.write(yaml_output)
          end
        end
      else
        logger.info("  No context keys found")
      end
    end
  end
end
