# frozen_string_literal: true

module ProductTaxonomy
  class Cli < Thor
    desc "dist", "Generate the taxonomy distribution"
    def dist
      seconds = Benchmark.realtime do
        Value.load_from_source(source_data: YAML.safe_load_file("../data/values.yml"))
      end
      puts "Loaded in #{seconds} seconds"
    end
  end
end
