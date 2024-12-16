# frozen_string_literal: true

module ProductTaxonomy
  class FindUnmappedExternalCategoriesCommand < Command
    def execute(name_and_version)
      load_taxonomy # not actually used in this operation, but required by IntegrationVersion to resolve categories

      unless name_and_version.match?(%r{\A[a-z0-9_-]+/[^/]+\z})
        raise ArgumentError, "Invalid format. Expected 'name/version', got: #{name_and_version}"
      end

      # Load relevant IntegrationVersion using CLI argument
      integration_path = File.join(IntegrationVersion::INTEGRATIONS_PATH, name_and_version)
      integration_version = IntegrationVersion.load_from_source(integration_path:)

      # Output the unmapped external categories
      integration_version.unmapped_external_category_ids.each do |id|
        puts integration_version.full_names_by_id[id]["full_name"]
      end
    end
  end
end
