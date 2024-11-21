# frozen_string_literal: true

require "benchmark"
require_relative "../lib/product_taxonomy"

module ProductTaxonomy
  # These benchmarks are not part of the test suite, but are useful as a sanity check during development.
  # They're not part of the test suite because the runtimes fluctuate depending on the machine, so we can't reliably
  # make assertions about them.
  Benchmark.bm(40) do |x|
    x.report("Load values") do
      Value.load_from_source(YAML.safe_load_file("../data/values.yml"))
      Value.reset
    end

    x.report("Load values and attributes") do
      Value.load_from_source(YAML.safe_load_file("../data/values.yml"))
      Attribute.load_from_source(YAML.safe_load_file("../data/attributes.yml"))
      Value.reset
      Attribute.reset
    end

    x.report("Load values, attributes, and categories") do
      Value.load_from_source(YAML.safe_load_file("../data/values.yml"))
      Attribute.load_from_source(YAML.safe_load_file("../data/attributes.yml"))
      categories_source_data = Dir.glob("../data/categories/*.yml").each_with_object([]) do |file, array|
        array.concat(YAML.safe_load_file(file))
      end
      Category.load_from_source(categories_source_data)
      Value.reset
      Attribute.reset
      Category.reset
    end
  end
end
