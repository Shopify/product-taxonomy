# frozen_string_literal: true

require "test_helper"
require "minitest/benchmark"

module ProductTaxonomy
  class BenchmarkTest < Minitest::Benchmark
    class << self
      def bench_range
        (1..10000).step(1000)
      end
    end

    def bench_load_values
      source_data = YAML.safe_load_file("../data/values.yml")
      Value.load_from_source(source_data: source_data.first(10)) # prime caches

      assert_performance_linear do |n|
        Value.load_from_source(source_data: source_data.first(n))
      end
    end
  end
end
