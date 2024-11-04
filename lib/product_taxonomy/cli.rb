# frozen_string_literal: true

module ProductTaxonomy
  class Cli < Thor
    desc "dist", "Generate the taxonomy distribution"
    def dist
      elapsed_time = Benchmark.realtime do
        taxonomy = Taxonomy.load_from_source
        File.write("dist/categories.json", JSON.pretty_generate(taxonomy.to_categories_json))
      end
      puts "Generated dist/categories.json in #{elapsed_time} seconds"
    end

    desc "print", "Print the taxonomy"
    def print
      taxonomy = nil
      elapsed_time = Benchmark.realtime do
        taxonomy = Taxonomy.load_from_source
      end
      puts taxonomy
      puts "Built taxonomy tree in #{elapsed_time} seconds"
    end

    desc "reparent CATEGORY_ID NEW_PARENT_ID", "Move a category to a new parent"
    def reparent(category_id, parent_id)
      taxonomy = Taxonomy.load_from_source
      categories = taxonomy.to_a
      category = categories.find { _1.id == category_id }
      new_parent = categories.find { _1.id == parent_id }
      category.reparent!(new_parent)
      puts taxonomy
    end

    desc "integrations INTEGRATION_PATH", "Generate integrations"
    def integrations(integration_path)
      taxonomy = Taxonomy.load_from_source
      input_categories_by_id = taxonomy.to_a.each_with_object({}) { |category, hash| hash[category.id] = category }
      mappings = YAML.safe_load_file("data/integrations/" + integration_path + "/mappings/from_shopify.yml")
      output_categories_by_id = YAML.safe_load_file("data/integrations/" + integration_path + "/full_names.yml").each_with_object({}) do |category, hash|
        hash[category["id"]] = category
      end

      output_mapping_rules = mappings["rules"].map do |mapping|
        input_category = input_categories_by_id[mapping["input"]["product_category_id"]]
        output_category = output_categories_by_id[mapping["output"]["product_category_id"][0]&.to_i]
        {
          input: {
            category: {
              id: input_category.id,
              full_name: input_category.full_name,
            },
          },
          output: {
            category: [
              {
                id: output_category["id"],
                full_name: output_category["full_name"],
              },
            ],
          },
        }
      end

      output = {
        version: mappings["input_taxonomy"],
        mappings: {
          input_taxonomy: mappings["input_taxonomy"],
          output_taxonomy: mappings["output_taxonomy"],
          rules: output_mapping_rules,
        },
      }

      output_filename = mappings["input_taxonomy"] + "_to_" + mappings["output_taxonomy"] + ".json"
      File.write("dist/" + output_filename.gsub("/", "_"), JSON.pretty_generate(output))
    end
  end
end
