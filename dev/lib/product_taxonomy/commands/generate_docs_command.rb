# frozen_string_literal: true

module ProductTaxonomy
  class GenerateDocsCommand < Command
    UNSTABLE = "unstable"

    class << self
      def docs_path
        File.expand_path("../docs", ProductTaxonomy.data_path)
      end
    end

    def initialize(options)
      super

      @version = validate_and_sanitize_version!(options[:version]) || UNSTABLE
    end

    def execute
      logger.info("Version: #{@version}")

      load_taxonomy
      generate_data_files
      generate_release_folder unless @version == UNSTABLE
    end

    private

    def generate_data_files
      data_target = File.expand_path("_data/#{@version}", self.class.docs_path)
      FileUtils.mkdir_p(data_target)

      logger.info("Generating sibling groups...")
      sibling_groups_yaml = YAML.dump(Serializers::Category::Docs::SiblingsSerializer.serialize_all, line_width: -1)
      File.write("#{data_target}/sibling_groups.yml", sibling_groups_yaml)

      logger.info("Generating category search index...")
      search_index_json = JSON.fast_generate(Serializers::Category::Docs::SearchSerializer.serialize_all)
      File.write("#{data_target}/search_index.json", search_index_json + "\n")

      logger.info("Generating attributes...")
      attributes_yml = YAML.dump(Serializers::Attribute::Docs::BaseAndExtendedSerializer.serialize_all, line_width: -1)
      File.write("#{data_target}/attributes.yml", attributes_yml)

      logger.info("Generating mappings...")
      mappings_json = JSON.parse(File.read(File.expand_path(
        "../dist/en/integrations/all_mappings.json",
        ProductTaxonomy.data_path,
      )))
      mappings_data = reverse_shopify_mapping_rules(mappings_json.fetch("mappings"))
      mappings_yml = YAML.dump(mappings_data, line_width: -1)
      File.write("#{data_target}/mappings.yml", mappings_yml)

      logger.info("Generating attributes with categories...")
      reversed_attributes_yml = YAML.dump(
        Serializers::Attribute::Docs::ReversedSerializer.serialize_all,
        line_width: -1,
      )
      File.write("#{data_target}/reversed_attributes.yml", reversed_attributes_yml)

      logger.info("Generating attribute with categories search index...")
      attribute_search_index_json = JSON.fast_generate(Serializers::Attribute::Docs::SearchSerializer.serialize_all)
      File.write("#{data_target}/attribute_search_index.json", attribute_search_index_json + "\n")
    end

    def generate_release_folder
      logger.info("Generating release folder...")

      release_path = File.expand_path("_releases/#{@version}", self.class.docs_path)
      FileUtils.mkdir_p(release_path)

      logger.info("Generating index.html...")
      content = File.read(File.expand_path("_releases/_index_template.html", self.class.docs_path))
      content.gsub!("TITLE", @version.upcase)
      content.gsub!("TARGET", @version)
      content.gsub!("GH_URL", "https://github.com/Shopify/product-taxonomy/releases/tag/v#{@version}")
      File.write("#{release_path}/index.html", content)

      logger.info("Generating attributes.html...")
      content = File.read(File.expand_path("_releases/_attributes_template.html", self.class.docs_path))
      content.gsub!("TITLE", @version.upcase)
      content.gsub!("TARGET", @version)
      content.gsub!("GH_URL", "https://github.com/Shopify/product-taxonomy/releases/tag/v#{@version}")
      File.write("#{release_path}/attributes.html", content)

      logger.info("Generating latest.html...")
      latest_html_path = File.expand_path("_releases/latest.html", self.class.docs_path)
      latest_html_content = <<~HTML
        ---
        title: latest
        include_in_release_list: true
        redirect_to: /releases/#{@version}/
        ---
      HTML
      File.write(latest_html_path, latest_html_content)
    end

    def reverse_shopify_mapping_rules(mappings)
      mappings.each do |mapping|
        next unless mapping["output_taxonomy"].include?("shopify")

        mapping["input_taxonomy"], mapping["output_taxonomy"] = mapping["output_taxonomy"], mapping["input_taxonomy"]
        mapping["rules"] = mapping["rules"].flat_map do |rule|
          rule["output"]["category"].map do |output_category|
            {
              "input" => { "category" => output_category },
              "output" => { "category" => [rule["input"]["category"]] },
            }
          end
        end
      end
    end
  end
end
