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

    test "load_taxonomy loads taxonomy resources and runs post-loading validations" do
      ProductTaxonomy::Category.stubs(:all).returns([])

      ProductTaxonomy.stubs(:data_path).returns("/fake/path")
      YAML.stubs(:load_file).returns({})
      Dir.stubs(:glob).returns(["/fake/path/categories/test.yml"])
      YAML.stubs(:safe_load_file).returns([])

      ProductTaxonomy::Value.expects(:load_from_source).once
      ProductTaxonomy::Attribute.expects(:load_from_source).once
      ProductTaxonomy::Category.expects(:load_from_source).once

      command = TestCommand.new({})
      mock_value = mock("value")
      ProductTaxonomy::Value.expects(:all).returns([mock_value])
      mock_value.expects(:validate!).with(:taxonomy_loaded)

      command.load_taxonomy
    end

    test "load_taxonomy skips loading if categories already exist" do
      ProductTaxonomy::Category.stubs(:all).returns([Category.new(id: "aa", name: "Test")])

      ProductTaxonomy::Value.expects(:load_from_source).never
      ProductTaxonomy::Attribute.expects(:load_from_source).never
      ProductTaxonomy::Category.expects(:load_from_source).never

      command = TestCommand.new({})
      command.expects(:run_taxonomy_loaded_validations).never

      command.load_taxonomy
    end
  end
end
