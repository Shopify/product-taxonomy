# frozen_string_literal: true

module ProductTaxonomy
  class SyncEnLocalizationsCommand < Command
    PERMITTED_TARGETS = ["categories", "attributes", "values"].freeze

    def initialize(options)
      super
      load_taxonomy
      @targets = options[:targets]&.split(",") || PERMITTED_TARGETS
      @targets.each do |target|
        raise "Invalid target: #{target}. Must be one of: #{PERMITTED_TARGETS.join(', ')}" unless PERMITTED_TARGETS.include?(target)
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

    def write_localizations(type, localizations)
      file_path = File.expand_path("localizations/#{type}/en.yml", ProductTaxonomy.data_path)
      File.open(file_path, "w") do |file|
        file.puts "# This file is auto-generated. Do not edit directly."
        file.write(YAML.dump(localizations, line_width: -1))
      end
      logger.info("Wrote #{type} localizations to #{file_path}")
    end
  end
end
