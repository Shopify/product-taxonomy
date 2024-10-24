# frozen_string_literal: true

class GenerateDocsCommand < ApplicationCommand
  UNSTABLE = "unstable"
  ATTRIBUTE_KEYS = ["id", "name", "handle"].freeze
  VALUE_KEYS = ["id", "name"].freeze

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
      generate_release_folder unless params[:version] == UNSTABLE
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
        file.write(YamlSerializer.dump(Category.as_json_for_docs_siblings(category_data)))
        file.write("\n")
      end
      sp.update_title("Generated sibling groups")
    end

    spinner("Generating category search index") do |sp|
      sys.write_file("#{data_target}/search_index.json") do |file|
        file.write(JSON.fast_generate(Category.as_json_for_docs_search(category_data)))
        file.write("\n")
      end
      sp.update_title("Generated category search index")
    end

    spinner("Generating attributes") do |sp|
      sys.write_file("#{data_target}/attributes.yml") do |file|
        file.write(YamlSerializer.dump(generate_extended_attributes(attribute_data)))
        file.write("\n")
      end
      sp.update_title("Generated attributes")
    end

    spinner("Generating mappings") do |sp|
      mappings = Docs::Mappings.new
      mappings_json = sys.parse_json("dist/en/integrations/all_mappings.json").fetch("mappings")
      mappings_data = mappings.reverse_shopify_mapping_rules(mappings_json)

      sys.write_file("#{data_target}/mappings.yml") do |file|
        file.write(YamlSerializer.dump(mappings_data))
        file.write("\n")
      end
      sp.update_title("Generated mappings")
    end

    spinner("Generating attributes with categories") do |sp|
      sys.write_file("#{data_target}/reversed_attributes.yml") do |file|
        file.write(YamlSerializer.dump(Attribute.as_json_for_docs))
        file.write("\n")
      end
      sp.update_title("Generated attributes with categories")
    end

    spinner("Generating attribute with categories search index") do |sp|
      sys.write_file("#{data_target}/attribute_search_index.json") do |file|
        file.write(JSON.fast_generate(Attribute.as_json_for_docs_search))
        file.write("\n")
      end
      sp.update_title("Generated attribute with categories search index")
    end
  end

  def generate_release_folder
    spinner("Generating release folder") do |sp|
      sys.write_file("docs/_releases/#{params[:version]}/index.html") do |file|
        content = sys.read_file("docs/_releases/_index_template.html")
        content.gsub!("TITLE", params[:version].upcase)
        content.gsub!("TARGET", params[:version])
        content.gsub!("GH_URL", "https://github.com/Shopify/product-taxonomy/releases/tag/v#{params[:version]}")
        file.write(content)
      end
      sys.write_file("docs/_releases/#{params[:version]}/attributes.html") do |file|
        content = sys.read_file("docs/_releases/_attributes_template.html")
        content.gsub!("TITLE", params[:version].upcase)
        content.gsub!("TARGET", params[:version])
        content.gsub!("GH_URL", "https://github.com/Shopify/product-taxonomy/releases/tag/v#{params[:version]}")
        file.write(content)
      end
      sp.update_title("Generated release folder")
    end
  end

  def generate_extended_attributes(attribute_data)
    result = attribute_data.each_with_object([]) do |attribute, acc|
      if attribute["extended_attributes"].any?
        attribute["extended_attributes"].each do |extended_attribute|
          acc << attribute.slice(*ATTRIBUTE_KEYS).merge(
            "handle" => extended_attribute.fetch("handle"),
            "extended_name" => extended_attribute.fetch("name"),
            "values" => attribute.fetch("values").map { |value| value.slice(*VALUE_KEYS) },
          )
        end
      end
      acc << attribute.slice(*ATTRIBUTE_KEYS).merge(
        "values" => attribute.fetch("values").map { |value| value.slice(*VALUE_KEYS) },
      )
    end
    result
  end
end
