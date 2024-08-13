# frozen_string_literal: true

class GenerateDocsCommand < ApplicationCommand
  UNSTABLE = "unstable"

  usage do
    no_command
  end

  option :version do
    desc "Documentation version"
    long "--version string"
    default UNSTABLE
  end

  def execute
    setup_options
    frame("Generating documentation files") do
      logger.headline("Version: #{params[:version]}")

      generate_data_files
      generate_release_file unless params[:version] == UNSTABLE
    end
  end

  private

  def setup_options
    params[:force] = true if params[:version] == UNSTABLE
  end

  def generate_data_files
    data_target = "docs/_data/#{params[:version]}"

    taxonomy_data = sys.parse_json("dist/en/taxonomy.json")
    category_data = taxonomy_data.fetch("verticals")
    attribute_data = taxonomy_data.fetch("attributes")

    spinner("Generating sibling groups") do |sp|
      sys.write_file("#{data_target}/sibling_groups.yml") do |file|
        file.write(Category.as_json_for_docs_siblings(category_data).to_yaml(line_width: -1))
        file.write("\n")
      end
      sp.update_title("Generated sibling groups")
    end

    spinner("Generating search index") do |sp|
      sys.write_file("#{data_target}/search_index.json") do |file|
        file.write(JSON.fast_generate(Category.as_json_for_docs_search(category_data)))
        file.write("\n")
      end
      sp.update_title("Generated search index")
    end

    spinner("Generating attributes") do |sp|
      sys.write_file("#{data_target}/attributes.yml") do |file|
        file.write(attribute_data.to_yaml(line_width: -1))
        file.write("\n")
      end
      sp.update_title("Generated attributes")
    end

    spinner("Generating mappings") do |sp|
      mappings = Docs::Mappings.new
      mappings_json = sys.parse_json("dist/en/integrations/all_mappings.json").fetch("mappings")
      mappings_data = mappings.reverse_shopify_mapping_rules(mappings_json)

      sys.write_file("#{data_target}/mappings.yml") do |file|
        file.write(mappings_data.to_yaml(line_width: -1))
        file.write("\n")
      end
      sp.update_title("Generated mappings")
    end
  end

  def generate_release_file
    spinner("Generating release file") do |sp|
      sys.write_file("docs/_releases/#{params[:version]}.html") do |file|
        content = sys.read_file("docs/_releases/_template.html")
        content.gsub!("TITLE", params[:version].upcase)
        content.gsub!("TARGET", params[:version])
        content.gsub!("GH_URL", "https://github.com/Shopify/product-taxonomy/releases/tag/v#{params[:version]}")
        file.write(content)
      end
      sp.update_title("Generated release file")
    end
  end
end
