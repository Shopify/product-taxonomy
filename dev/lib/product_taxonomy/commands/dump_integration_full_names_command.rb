# frozen_string_literal: true

module ProductTaxonomy
  class DumpIntegrationFullNamesCommand < Command
    def initialize(options)
      super

      @version = options[:version] || File.read(version_file_path).strip
    end

    def execute
      logger.info("Dumping full names from current taxonomy for integrations...")
      logger.info("Version: #{@version}")

      load_taxonomy
      ensure_integration_exists

      path = File.expand_path("shopify/#{@version}/full_names.yml", integration_data_path)
      FileUtils.mkdir_p(File.dirname(path))

      data = Serializers::Category::Data::FullNamesSerializer.serialize_all
      File.write(path, YAML.dump(data, line_width: -1))

      logger.info("Dumped to `#{path}`")
    end

    private

    def ensure_integration_exists
      FileUtils.mkdir_p(File.expand_path("shopify/#{@version}", integration_data_path))

      integration_version = "shopify/#{@version}"
      integrations_file = File.expand_path("integrations.yml", integration_data_path)
      integrations = YAML.safe_load_file(integrations_file)

      integration = integrations.find { _1["name"] == "shopify" }
      return if integration["available_versions"].include?(integration_version)

      integration["available_versions"] << integration_version
      File.write(integrations_file, YAML.dump(integrations, line_width: -1))
    end

    def integration_data_path = IntegrationVersion::INTEGRATIONS_PATH
  end
end
