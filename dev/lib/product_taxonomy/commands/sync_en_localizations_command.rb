# frozen_string_literal: true

module ProductTaxonomy
  class SyncEnLocalizationsCommand < Command
    PERMITTED_TARGETS = ["categories", "attributes", "values"].freeze

    def initialize(options)
      super
      load_taxonomy
      @targets = options[:targets]&.split(",") || PERMITTED_TARGETS
      @targets.each do |target|
        raise "Invalid target: #{target}. Must be one of: #{PERMITTED_TARGETS.join(", ")}" unless PERMITTED_TARGETS.include?(target)
      end
    end

    def execute
      logger.info("Syncing EN localizations")

      sync_categories if @targets.include?("categories")
      sync_attributes if @targets.include?("attributes")
      sync_values if @targets.include?("values")
    end

    private

    def sync_categories
      logger.info("Syncing categories...")
      localizations = Serializers::Category::Data::LocalizationsSerializer.serialize_all
      write_localizations("categories", localizations)
    end

    def sync_attributes
      logger.info("Syncing attributes...")
      localizations = Serializers::Attribute::Data::LocalizationsSerializer.serialize_all
      write_localizations("attributes", localizations)
    end

    def sync_values
      logger.info("Syncing values...")
      localizations = Serializers::Value::Data::LocalizationsSerializer.serialize_all
      write_localizations("values", localizations)
    end

    # Writes localization data to a YAML file with 'context' keys converted to comments.
    # Uses YAML.dump for formatting, then injects context as comments above entry fields.
    def write_localizations(type, localizations)
      file_path = File.expand_path("localizations/#{type}/en.yml", ProductTaxonomy.data_path)

      context_map = extract_contexts(localizations)

      yaml_output = YAML.dump(localizations, line_width: -1)
      yaml_with_comments = inject_context_comments(yaml_output, context_map, type)

      File.open(file_path, "w") do |file|
        file.puts "# This file is auto-generated. Do not edit directly."
        file.write(yaml_with_comments)
      end
      logger.info("Wrote #{type} localizations to #{file_path}")
    end

    # Extracts and removes 'context' keys from the localization hash.
    #
    # Expects a specific structure from LocalizationsSerializer:
    #   { "en" => { "section" => { "entry-id" => { "name" => "...", "context" => "..." } } } }
    #
    # Note: This creates a flat map keyed by entry ID only, so it assumes entry IDs are unique
    # across all sections. In practice, each file (categories/attributes/values) contains only
    # one section, so there are no collisions.
    #
    # Returns a map of entry IDs to their context strings.
    def extract_contexts(localizations)
      context_map = {}
      _locale, nested = localizations.first

      nested.each do |_section, entries|
        entries.each do |id, data|
          if data.key?("context")
            context_map[id] = data.delete("context")
          end
        end
      end

      context_map
    end

    # Injects context strings as YAML comments below entry IDs (above the first field).
    def inject_context_comments(yaml_output, context_map, type)
      lines = yaml_output.lines
      result = []

      lines.each_with_index do |line, index|
        result << line

        # Match lines with format "  key:" and check if they're entry IDs (not field names)
        if line.match?(/^(\s+)(.+):$/)
          current_indent = line[/^(\s+)/, 1]
          entry_id = line.strip.chomp(":")
          next_line = lines[index + 1]

          # Entry IDs have fields indented more than themselves
          # Field names (like "name:") have values at same or less indentation
          is_entry_id = next_line&.match?(/^(\s+)/) && next_line[/^(\s+)/, 1].length > current_indent.length

          if is_entry_id && context_map.key?(entry_id)
            field_indent = next_line[/^(\s+)/, 1]
            result << "#{field_indent}# #{context_map[entry_id]}\n"
          end
        end
      end

      result.join
    end
  end
end
