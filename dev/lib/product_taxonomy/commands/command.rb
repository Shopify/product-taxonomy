# frozen_string_literal: true

require "logger"
require "benchmark"

module ProductTaxonomy
  class Command
    attr_reader :logger, :options

    def initialize(options)
      @options = options
      @logger = Logger.new($stdout, level: :info)
      @logger.formatter = proc { |_, _, _, msg| "#{msg}\n" }
      @logger.level = :debug if options[:verbose]
      @logger.level = :error if options[:quiet]
    end

    def run(...)
      elapsed = Benchmark.realtime do
        execute(...)
      end
      logger.info("Completed in #{elapsed.round(2)} seconds")
    rescue => e
      logger.error("\e[1;31mError:\e[0m #{e.message}")
      exit(1)
    end

    def execute(...)
      raise NotImplementedError, "#{self.class}#execute must be implemented"
    end

    def load_taxonomy
      return if ProductTaxonomy::Category.all.any?

      ProductTaxonomy::Value.load_from_source(YAML.load_file(File.expand_path(
        "values.yml",
        ProductTaxonomy.data_path,
      )))
      ProductTaxonomy::Attribute.load_from_source(YAML.load_file(File.expand_path(
        "attributes.yml",
        ProductTaxonomy.data_path,
      )))

      glob = Dir.glob(File.expand_path("categories/*.yml", ProductTaxonomy.data_path))
      categories_source_data = glob.each_with_object([]) do |file, array|
        array.concat(YAML.safe_load_file(file))
      end
      ProductTaxonomy::Category.load_from_source(categories_source_data)
    end

    def validate_and_sanitize_version!(version)
      return version if version.nil?

      sanitized_version = version.to_s.strip
      unless sanitized_version.match?(/\A[a-zA-Z0-9.-]+\z/) && !sanitized_version.include?("..")
        raise ArgumentError,
          "Invalid version format. Version can only contain alphanumeric characters, dots, and dashes."
      end

      sanitized_version
    end

    def version_file_path
      File.expand_path("../VERSION", ProductTaxonomy.data_path)
    end

    def locales_defined_in_data_path
      glob = Dir.glob(File.expand_path("localizations/categories/*.yml", ProductTaxonomy.data_path))
      glob.map { File.basename(_1, ".yml") }
    end
  end
end
