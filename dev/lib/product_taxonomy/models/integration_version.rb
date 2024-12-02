# frozen_string_literal: true

module ProductTaxonomy
  # A single version of an integration, e.g. "shopify/2024-07".
  #
  # Includes:
  # - The full names of categories in the integration's taxonomy.
  # - The mapping rules for converting between the integration's taxonomy and Shopify's taxonomy.
  class IntegrationVersion
    class << self
      # Generate all distribution files for all integration versions.
      #
      # @param output_path [String] The path to the output directory.
      def generate_all_distributions(output_path:, logger:, base_path: nil)
        load_all_from_source(base_path:).each { _1.generate_distributions(output_path:, logger:) }
      end

      # Load all integration versions from the source data directory.
      #
      # @return [Array<IntegrationVersion>]
      def load_all_from_source(base_path: nil)
        base_path ||= File.expand_path("integrations", ProductTaxonomy::DATA_PATH)
        integration_versions = Dir.glob("*/*", base: base_path)
        integration_versions.map do |integration_version|
          integration_path = File.expand_path(integration_version, base_path)
          load_from_source(integration_path:)
        end
      end

      # Load an integration version from the provided source data directory.
      #
      # @param integration_path [String] The path to the integration version source data directory.
      # @return [IntegrationVersion]
      def load_from_source(integration_path:)
        full_names = YAML.safe_load_file(File.expand_path("full_names.yml", integration_path))
        full_names_by_id = full_names.each_with_object({}) { |data, hash| hash[data["id"].to_s] = data }

        from_shopify_mappings = MappingRule.load_rules_from_source(
          integration_path:,
          direction: :from_shopify,
          full_names_by_id:,
        )
        to_shopify_mappings = MappingRule.load_rules_from_source(
          integration_path:,
          direction: :to_shopify,
          full_names_by_id:,
        )

        integration_pathname = Pathname.new(integration_path)

        new(
          name: integration_pathname.parent.basename.to_s,
          version: integration_pathname.basename.to_s,
          full_names_by_id:,
          from_shopify_mappings:,
          to_shopify_mappings:,
        )
      end
    end

    attr_reader :name, :version

    def initialize(name:, version:, full_names_by_id:, from_shopify_mappings: nil, to_shopify_mappings: nil)
      @name = name
      @version = version
      @full_names_by_id = full_names_by_id
      @from_shopify_mappings = from_shopify_mappings
      @to_shopify_mappings = to_shopify_mappings
    end

    # Generate all distribution files for the integration version.
    #
    # @param output_path [String] The path to the output directory.
    def generate_distributions(output_path:, logger:)
      logger.info("Generating integration mappings for #{@name}/#{@version}")
      generate_distribution(output_path:, direction: :from_shopify) if @from_shopify_mappings.present?
      generate_distribution(output_path:, direction: :to_shopify) if @to_shopify_mappings.present?
    end

    # Generate JSON and TXT distribution files for a single direction of the integration version.
    #
    # @param output_path [String] The path to the output directory.
    # @param direction [Symbol] The direction of the distribution file to generate (:from_shopify or :to_shopify).
    def generate_distribution(output_path:, direction:)
      output_dir = File.expand_path("en/integrations/#{@name}", output_path)
      FileUtils.mkdir_p(output_dir)

      File.write(
        File.expand_path("#{distribution_filename(direction:)}.json", output_dir),
        JSON.pretty_generate(to_json(direction:)),
      )
      File.write(
        File.expand_path("#{distribution_filename(direction:)}.txt", output_dir),
        to_txt(direction:),
      )
    end

    # Generate a JSON representation of the integration version for a single direction.
    #
    # @param direction [Symbol] The direction of the distribution file to generate (:from_shopify or :to_shopify).
    # @return [Hash]
    def to_json(direction:)
      mappings = direction == :from_shopify ? @from_shopify_mappings : @to_shopify_mappings
      {
        version: current_shopify_version,
        mappings: [{
          input_taxonomy: input_name_and_version(direction:),
          output_taxonomy: output_name_and_version(direction:),
          rules: mappings.map(&:to_json),
        }],
      }
    end

    # Generate a TXT representation of the integration version for a single direction.
    #
    # @param direction [Symbol] The direction of the distribution file to generate (:from_shopify or :to_shopify).
    # @return [String]
    def to_txt(direction:)
      mappings = direction == :from_shopify ? @from_shopify_mappings : @to_shopify_mappings

      header = <<~TXT
        # Shopify Product Taxonomy - Mapping #{input_name_and_version(direction:)} to #{output_name_and_version(direction:)}
        # Format:
        # → {base taxonomy category name}
        # ⇒ {mapped taxonomy category name}

      TXT
      header + mappings.map(&:to_txt).join("\n")
    end

    private

    def distribution_filename(direction:)
      "#{input_name_and_version(direction:)}_to_#{output_name_and_version(direction:)}"
        .gsub("/", "_")
        .gsub("-unstable", "")
    end

    def integration_name_and_version
      "#{@name}/#{@version}"
    end

    def shopify_name_and_version
      "shopify/#{current_shopify_version}"
    end

    def current_shopify_version
      @current_shopify_version ||= File.read(File.expand_path("../VERSION", ProductTaxonomy::DATA_PATH)).strip
    end

    def input_name_and_version(direction:)
      direction == :from_shopify ? shopify_name_and_version : integration_name_and_version
    end

    def output_name_and_version(direction:)
      direction == :from_shopify ? integration_name_and_version : shopify_name_and_version
    end
  end
end
