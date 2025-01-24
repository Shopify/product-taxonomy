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
    end

    def execute(...)
      raise NotImplementedError, "#{self.class}#execute must be implemented"
    end

    def load_taxonomy
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
  end
end
