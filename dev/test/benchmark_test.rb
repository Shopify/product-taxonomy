# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class BenchmarkTest < Minitest::Benchmark
    class << self
      def bench_range
        (1..10000).step(1000)
      end
    end

    def bench_load_values
      source_data = YAML.safe_load_file("../data/values.yml")
      Value.load_from_source(source_data.first(10)) # warmup
      Value.reset

      assert_performance_linear do |n|
        Value.load_from_source(source_data.first(n))
        Value.reset
      end
    end
  end
end
