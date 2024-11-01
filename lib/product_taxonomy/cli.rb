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
  end
end
