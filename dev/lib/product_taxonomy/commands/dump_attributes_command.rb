# frozen_string_literal: true

module ProductTaxonomy
  class DumpAttributesCommand < Command
    def execute
      logger.info("Dumping attributes...")

      load_taxonomy

      path = File.expand_path("attributes.yml", ProductTaxonomy.data_path)
      FileUtils.mkdir_p(File.dirname(path))

      data = Serializers::Attribute::Data::DataSerializer.serialize_all
      File.write(path, YAML.dump(data, line_width: -1))

      logger.info("Updated `#{path}`")
    end
  end
end
