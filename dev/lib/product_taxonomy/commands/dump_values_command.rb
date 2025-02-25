# frozen_string_literal: true

module ProductTaxonomy
  class DumpValuesCommand < Command
    def execute
      logger.info("Dumping values...")

      load_taxonomy

      path = File.expand_path("values.yml", ProductTaxonomy.data_path)
      FileUtils.mkdir_p(File.dirname(path))

      data = Serializers::Value::Data::DataSerializer.serialize_all
      File.write(path, YAML.dump(data, line_width: -1))

      logger.info("Updated `#{path}`")
    end
  end
end
