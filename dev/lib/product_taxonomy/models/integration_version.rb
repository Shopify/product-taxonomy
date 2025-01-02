# frozen_string_literal: true

module ProductTaxonomy
  # A single version of an integration, e.g. "shopify/2024-07".
  #
  # Includes:
  # - The full names of categories in the integration's taxonomy.
  # - The mapping rules for converting between the integration's taxonomy and Shopify's taxonomy.
  class IntegrationVersion
    INTEGRATIONS_PATH = File.expand_path("integrations", ProductTaxonomy::DATA_PATH)

    class << self
      # Generate all distribution files for all integration versions.
      #
      # @param output_path [String] The path to the output directory.
      # @param logger [Logger] The logger to use for logging messages.
      # @param current_shopify_version [String] The current version of the Shopify taxonomy.
      # @param base_path [String] The path to the base directory containing integration versions.
      def generate_all_distributions(output_path:, logger:, current_shopify_version: nil, base_path: INTEGRATIONS_PATH)
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
      def load_all_from_source(current_shopify_version: nil, base_path: INTEGRATIONS_PATH)
        integrations_yaml = YAML.safe_load_file(File.expand_path("integrations.yml", base_path))
        integrations_yaml.flat_map do |integration_yaml|
          versions = integration_yaml["available_versions"].sort.map do |version_path|
            load_from_source(
              integration_path: File.expand_path(version_path, base_path),
              current_shopify_version:,
            )
          end

          resolve_to_shopify_mappings_chain(versions) if integration_yaml["name"] == "shopify"

          versions
        end
      end

      # Resolve a set of IntegrationVersion to_shopify mappings so that each one maps to the latest version of the
      # Shopify taxonomy.
      #
      # @param versions [Array<IntegrationVersion>] The versions to resolve, ordered from oldest to newest.
      def resolve_to_shopify_mappings_chain(versions)
        # Resolve newest version against current taxonomy
        versions.last.resolve_to_shopify_mappings(nil)

        # Resolve each older version against the one following it
        versions.each_cons(2).reverse_each do |previous, next_version|
          previous.resolve_to_shopify_mappings(next_version)
        end
      end

      # Load an integration version from the provided source data directory.
      #
      # @param integration_path [String] The path to the integration version source data directory.
      # @return [IntegrationVersion]
      def load_from_source(integration_path:, current_shopify_version: nil)
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
          JSON.pretty_generate(to_json(mappings:, current_shopify_version:)) + "\n",
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

    attr_reader :name, :version, :from_shopify_mappings, :to_shopify_mappings, :full_names_by_id

    # @param name [String] The name of the integration.
    # @param version [String] The version of the integration.
    # @param full_names_by_id [Hash<String, Hash>] A hash of full names by ID.
    # @param current_shopify_version [String] The current version of the Shopify taxonomy.
    # @param from_shopify_mappings [Array<MappingRule>] The mappings from the Shopify taxonomy to the integration's
    #   taxonomy.
    # @param to_shopify_mappings [Array<MappingRule>] The mappings from the integration's taxonomy to the Shopify
    #   taxonomy.
    def initialize(
      name:,
      version:,
      full_names_by_id:,
      current_shopify_version: nil,
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
        JSON.pretty_generate(json) + "\n",
      )
      File.write(
        File.expand_path("#{distribution_filename(direction:)}.txt", output_dir),
        to_txt(direction:) + "\n",
      )
    end

    # Resolve the output categories of to_shopify mappings to the next version of the Shopify taxonomy.
    #
    # @param next_integration_version [IntegrationVersion | nil] The IntegrationVersion defining mappings to the next
    #   newer version of the Shopify taxonomy. If nil, the latest version of the Shopify taxonomy is used.
    def resolve_to_shopify_mappings(next_integration_version)
      @to_shopify_mappings.each do |mapping|
        newer_mapping = next_integration_version&.to_shopify_mappings&.find do
          _1.input_category["id"] == mapping.output_category
        end
        mapping.output_category = newer_mapping&.output_category || Category.find_by(id: mapping.output_category)
      end
    end

    # For a mapping to an external taxonomy, get the IDs of external categories that are not mapped from Shopify.
    #
    # @return [Array<String>] IDs of external categories not mapped from the Shopify taxonomy. Empty if there are no
    #   mappings from Shopify.
    def unmapped_external_category_ids
      return [] if @from_shopify_mappings.blank?

      mappings_by_output_category_id = @from_shopify_mappings.index_by { _1.output_category["id"].to_s }
      @full_names_by_id.keys - mappings_by_output_category_id.keys
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
        mappings = if direction == :from_shopify
          @from_shopify_mappings&.sort_by { _1.input_category.id_parts }
        else
          @to_shopify_mappings
        end

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

      visible_mappings = mappings.filter_map do |mapping|
        next if @name == "shopify" && direction == :to_shopify && mapping.input_txt_equals_output_txt?

        mapping.to_txt
      end

      header + visible_mappings.sort.join("\n").chomp
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
