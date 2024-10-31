# frozen_string_literal: true

require "yaml"
require "json"
require "benchmark"

require_relative "models/category"
require_relative "models/taxonomy"

module ProductTaxonomy
  class CLI
    class << self
      def start(args)
        taxonomy = nil
        elapsed_time = Benchmark.realtime do
          taxonomy = Taxonomy.load_from_source
        end
        puts taxonomy

        if taxonomy.valid?
          puts "Taxonomy is valid"
        else
          puts "Invalid taxonomy: #{taxonomy.errors.full_messages.join(", ")}"
        end
        puts "Elapsed time: #{elapsed_time} seconds"
      end

      def generate_dist_files
        elapsed_time = Benchmark.realtime do
          taxonomy = Taxonomy.load_from_source
          File.write("dist/categories.json", JSON.pretty_generate(taxonomy.to_categories_json))
        end
        puts "Generated dist/categories.json in #{elapsed_time} seconds"
      end
    end
  end
end
