# frozen_string_literal: true

require "yaml"
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
    end
  end
end
