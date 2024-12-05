# frozen_string_literal: true

module ProductTaxonomy
  # A mapping rule for converting between the integration's taxonomy and Shopify's taxonomy.
  class MappingRule
    class << self
      # Load mapping rules from the provided source data directory for a single direction.
      #
      # @param integration_path [String] The path to the integration version source data directory.
      # @param direction [Symbol] The direction of the mapping rules to load (:from_shopify or :to_shopify).
      # @param full_names_by_id [Hash<String, Hash>] A hash of full names by ID.
      # @return [Array<MappingRule>, nil]
      def load_rules_from_source(integration_path:, direction:, full_names_by_id:)
        file_path = File.expand_path("mappings/#{direction}.yml", integration_path)
        return unless File.exist?(file_path)

        data = YAML.safe_load_file(file_path)
        raise ArgumentError, "Mapping rules file does not contain a hash: #{file_path}" unless data.is_a?(Hash)
        raise ArgumentError, "Mapping rules file does not have a `rules` key: #{file_path}" unless data.key?("rules")
        unless data["rules"].is_a?(Array)
          raise ArgumentError, "Mapping rules file `rules` value is not an array: #{file_path}"
        end

        data["rules"].map do |rule|
          input_id = rule.dig("input", "product_category_id")&.to_s
          output_id = rule.dig("output", "product_category_id")&.first&.to_s

          raise ArgumentError, "Invalid mapping rule: #{rule}" if input_id.nil? || output_id.nil?

          is_to_shopify = direction == :to_shopify
          input_category = is_to_shopify ? full_names_by_id[input_id] : Category.find_by(id: input_id)
          output_category = is_to_shopify ? Category.find_by(id: output_id) : full_names_by_id[output_id]

          raise ArgumentError, "Input category not found for mapping rule: #{rule}" unless input_category
          raise ArgumentError, "Output category not found for mapping rule: #{rule}" unless output_category

          new(input_category:, output_category:)
        rescue TypeError, NoMethodError
          raise ArgumentError, "Invalid mapping rule: #{rule}"
        end
      end
    end

    attr_reader :input_category, :output_category

    def initialize(input_category:, output_category:)
      @input_category = input_category
      @output_category = output_category
    end

    # Generate a JSON representation of the mapping rule.
    #
    # @return [Hash]
    def to_json
      {
        input: {
          category: category_json(@input_category),
        },
        output: {
          category: [category_json(@output_category)],
        },
      }
    end

    # Generate a TXT representation of the mapping rule.
    #
    # @return [String]
    def to_txt
      <<~TXT
        → #{category_txt(@input_category)}
        ⇒ #{category_txt(@output_category)}
      TXT
    end

    # Whether the input and output categories have the same full name.
    #
    # @return [Boolean]
    def input_txt_equals_output_txt?
      category_txt(@input_category) == category_txt(@output_category)
    end

    private

    def category_json(category)
      if category.is_a?(Hash)
        {
          id: category["id"].to_s,
          full_name: category["full_name"],
        }
      else
        {
          id: category.gid,
          full_name: category.full_name,
        }
      end
    end

    def category_txt(category)
      if category.is_a?(Hash)
        category["full_name"]
      else
        category.full_name
      end
    end
  end
end
