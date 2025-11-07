# frozen_string_literal: true

module ProductTaxonomy
  class DumpReturnReasonsCommand < Command
    def execute
      logger.info("Dumping return reasons...")

      load_taxonomy

      path = File.expand_path("return_reasons.yml", ProductTaxonomy.data_path)
      FileUtils.mkdir_p(File.dirname(path))

      data = Serializers::ReturnReason::Data::DataSerializer.serialize_all
      File.write(path, YAML.dump(data, line_width: -1))

      logger.info("Updated `#{path}`")
    end
  end
end



