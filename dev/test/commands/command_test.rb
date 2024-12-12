# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class CommandTest < TestCase
    class TestCommand < Command
      def execute
        logger.debug("Debug message")
        logger.info("Info message")
        logger.error("Error message")
      end
    end

    test "run runs the command and prints the elapsed time" do
      assert_output("Info message\nError message\nCompleted in 0.1 seconds\n") do
        Benchmark.stubs(:realtime).returns(0.1).yields
        TestCommand.new({}).run
      end
    end

    test "run suppresses non-error output when quiet is true" do
      assert_output("Error message\n") do
        Benchmark.stubs(:realtime).returns(0.1).yields
        TestCommand.new(quiet: true).run
      end
    end

    test "run prints verbose output when verbose is true" do
      assert_output("Debug message\nInfo message\nError message\nCompleted in 0.1 seconds\n") do
        Benchmark.stubs(:realtime).returns(0.1).yields
        TestCommand.new(verbose: true).run
      end
    end
  end
end
