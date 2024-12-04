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
      # @param logger [Logger] The logger to use for logging messages.
      # @param current_shopify_version [String] The current version of the Shopify taxonomy.
      # @param base_path [String] The path to the base directory containing integration versions.
      def generate_all_distributions(output_path:, logger:, current_shopify_version:, base_path: nil)
        integration_versions = load_all_from_source(current_shopify_version:, base_path:)
        all_mappings = integration_versions.each_with_object([]) do |integration_version, all_mappings|
          logger.info("Generating integration mappings for #{integration_version.name}/#{integration_version.version}")
          integration_version.generate_distributions(output_path:)
          all_mappings.concat(integration_version.to_json(direction: :both))
        end
        generate_all_mappings_file(mappings: all_mappings, current_shopify_version:, output_path:)
      end

      # Load all integration versions from the source data directory.
      #
      # @return [Array<IntegrationVersion>]
      def load_all_from_source(current_shopify_version:, base_path: nil)
        base_path ||= File.expand_path("integrations", ProductTaxonomy::DATA_PATH)
        integration_versions = Dir.glob("*/*", base: base_path)
        integration_versions.map do |integration_version|
          integration_path = File.expand_path(integration_version, base_path)
          load_from_source(integration_path:, current_shopify_version:)
        end
      end

      # Load an integration version from the provided source data directory.
      #
      # @param integration_path [String] The path to the integration version source data directory.
      # @return [IntegrationVersion]
      def load_from_source(integration_path:, current_shopify_version:)
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
          current_shopify_version:,
        )
      end

      # Generate a JSON file containing all mappings for all integration versions.
      #
      # @param mappings [Array<Hash>] The mappings to include in the file.
      # @param version [String] The current version of the Shopify taxonomy.
      # @param output_path [String] The path to the output directory.
      def generate_all_mappings_file(mappings:, current_shopify_version:, output_path:)
        File.write(
          File.expand_path("all_mappings.json", integrations_output_path(output_path)),
          JSON.pretty_generate(to_json(mappings:, current_shopify_version:)),
        )
      end

      # Generate a JSON representation for a given set of mappings and version of the Shopify taxonomy.
      #
      # @param version [String] The current version of the Shopify taxonomy.
      # @param mappings [Array<Hash>] The mappings to include in the file.
      # @return [Hash]
      def to_json(current_shopify_version:, mappings:)
        {
          version: current_shopify_version,
          mappings:,
        }
      end

      # Generate the path to the integrations output directory.
      #
      # @param base_output_path [String] The base path to the output directory.
      # @return [String]
      def integrations_output_path(base_output_path)
        File.expand_path("en/integrations", base_output_path)
      end
    end

    attr_reader :name, :version, :from_shopify_mappings, :to_shopify_mappings

    def initialize(
      name:,
      version:,
      full_names_by_id:,
      current_shopify_version:,
      from_shopify_mappings: nil,
      to_shopify_mappings: nil
    )
      @name = name
      @version = version
      @full_names_by_id = full_names_by_id
      @current_shopify_version = current_shopify_version
      @from_shopify_mappings = from_shopify_mappings
      @to_shopify_mappings = to_shopify_mappings
      @to_json = {} # memoized by direction
    end

    # Generate all distribution files for the integration version.
    #
    # @param output_path [String] The path to the output directory.
    def generate_distributions(output_path:)
      generate_distribution(output_path:, direction: :from_shopify) if @from_shopify_mappings.present?
      generate_distribution(output_path:, direction: :to_shopify) if @to_shopify_mappings.present?
    end

    # Generate JSON and TXT distribution files for a single direction of the integration version.
    #
    # @param output_path [String] The path to the output directory.
    # @param direction [Symbol] The direction of the distribution file to generate (:from_shopify or :to_shopify).
    def generate_distribution(output_path:, direction:)
      output_dir = File.expand_path(@name, self.class.integrations_output_path(output_path))
      FileUtils.mkdir_p(output_dir)

      json = self.class.to_json(mappings: [to_json(direction:)], current_shopify_version: @current_shopify_version)
      File.write(
        File.expand_path("#{distribution_filename(direction:)}.json", output_dir),
        JSON.pretty_generate(json),
      )
      File.write(
        File.expand_path("#{distribution_filename(direction:)}.txt", output_dir),
        to_txt(direction:),
      )
    end

    # Generate a JSON representation of the integration version for a single direction.
    #
    # @param direction [Symbol] The direction of the distribution file to generate (:from_shopify or :to_shopify).
    # @return [Hash, Array<Hash>, nil]
    def to_json(direction:)
      if @to_json.key?(direction)
        @to_json[direction]
      elsif direction == :both
        [to_json(direction: :from_shopify), to_json(direction: :to_shopify)].compact
      else
        mappings = direction == :from_shopify ? @from_shopify_mappings : @to_shopify_mappings
        @to_json[direction] = if mappings.present?
          {
            input_taxonomy: input_name_and_version(direction:),
            output_taxonomy: output_name_and_version(direction:),
            rules: mappings.map(&:to_json),
          }
        end
      end
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
      "shopify/#{@current_shopify_version}"
    end

    def input_name_and_version(direction:)
      direction == :from_shopify ? shopify_name_and_version : integration_name_and_version
    end

    def output_name_and_version(direction:)
      direction == :from_shopify ? integration_name_and_version : shopify_name_and_version
    end
  end
end
