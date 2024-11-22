# frozen_string_literal: true

module ProductTaxonomy
  class GenerateDistCommand < Command
    OUTPUT_PATH = File.expand_path("../../../dist", __dir__)

    def initialize(options)
      super

      @version = options[:version] || File.read(File.expand_path("../../../../VERSION", __dir__)).strip
      @locales = if options[:locales] == ["all"]
        glob = Dir.glob(File.expand_path("localizations/categories/*.yml", ProductTaxonomy::DATA_PATH))
        glob.map { File.basename(_1, ".yml") }
      else
        options[:locales]
      end
      # These two are memoized since they get merged to form the "taxonomy" json file
      @categories_json_by_locale = {}
      @attributes_json_by_locale = {}
    end

    def execute
      logger.info("Version: #{@version}")
      logger.info("Locales: #{@locales.join(", ")}")

      load_taxonomy

      @locales.each { generate_dist_files(_1) }
    end

    private

    def generate_dist_files(locale)
      logger.info("Generating files for #{locale}")
      FileUtils.mkdir_p("#{OUTPUT_PATH}/#{locale}")
      ["categories", "attributes", "taxonomy", "attribute_values"].each do |type|
        generate_txt_file(locale:, type:)
        generate_json_file(locale:, type:)
      end
    end

    def generate_txt_file(locale:, type:)
      txt_data = case type
      when "categories" then Category.to_txt(version: @version, locale:)
      when "attributes" then Attribute.to_txt(version: @version, locale:)
      when "taxonomy" then return
      when "attribute_values" then Value.to_txt(version: @version, locale:)
      end

      File.write("#{OUTPUT_PATH}/#{locale}/#{type}.txt", txt_data)
    end

    def generate_json_file(locale:, type:)
      json_data = case type
      when "categories"
        @categories_json_by_locale[locale] ||= Category.to_json(version: @version, locale:)
      when "attributes"
        @attributes_json_by_locale[locale] ||= Attribute.to_json(version: @version, locale:)
      when "taxonomy"
        @categories_json_by_locale[locale].merge(@attributes_json_by_locale[locale])
      when "attribute_values"
        Value.to_json(version: @version, locale:)
      end

      File.write("#{OUTPUT_PATH}/#{locale}/#{type}.json", JSON.pretty_generate(json_data))
    end
  end
end
