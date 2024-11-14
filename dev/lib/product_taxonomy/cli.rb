# frozen_string_literal: true

module ProductTaxonomy
  class Cli < Thor
    desc "dist", "Generate the taxonomy distribution"
    def dist
      seconds = Benchmark.realtime do
        source_data = YAML.safe_load_file("../data/attributes.yml")
        values_model_index = Value.load_from_source(source_data: YAML.safe_load_file("../data/values.yml"))

        Attribute.load_from_source(
          source_data:,
          values: values_model_index.hashed_by(:friendly_id),
        )
      end
      puts "Loaded in #{seconds} seconds"
    end
  end
end
