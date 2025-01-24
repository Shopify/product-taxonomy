# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class GenerateDocsCommandTest < TestCase
    setup do
      @tmp_base_path = Dir.mktmpdir
      @real_base_path = File.expand_path("..", ProductTaxonomy.data_path)

      # Create test files
      FileUtils.mkdir_p(File.expand_path("data", @tmp_base_path))
      FileUtils.mkdir_p(File.expand_path("dist/en/integrations", @tmp_base_path))
      File.write(
        File.expand_path("dist/en/integrations/all_mappings.json", @tmp_base_path),
        JSON.fast_generate({
          "mappings" => [{
            "input_taxonomy" => ["shopify"],
            "output_taxonomy" => ["external"],
            "rules" => [{
              "input" => { "category" => "test" },
              "output" => { "category" => ["mapped"] },
            }],
          }],
        }),
      )

      # Copy template files
      FileUtils.mkdir_p(File.expand_path("docs/_releases", @tmp_base_path))
      FileUtils.cp(
        File.expand_path("docs/_releases/_index_template.html", @real_base_path),
        File.expand_path("docs/_releases/_index_template.html", @tmp_base_path),
      )
      FileUtils.cp(
        File.expand_path("docs/_releases/_attributes_template.html", @real_base_path),
        File.expand_path("docs/_releases/_attributes_template.html", @tmp_base_path),
      )

      GenerateDocsCommand.stubs(:docs_path).returns(File.expand_path("docs", @tmp_base_path))
      Command.any_instance.stubs(:load_taxonomy)
      Serializers::Category::Docs::SiblingsSerializer.stubs(:serialize_all).returns({ "siblings" => "foo" })
      Serializers::Category::Docs::SearchSerializer.stubs(:serialize_all).returns([{ "search" => "bar" }])
      Serializers::Attribute::Docs::BaseAndExtendedSerializer.stubs(:serialize_all).returns({ "attributes" => "baz" })
      Serializers::Attribute::Docs::ReversedSerializer.stubs(:serialize_all).returns({ "reversed" => "qux" })
      Serializers::Attribute::Docs::SearchSerializer.stubs(:serialize_all).returns([{ "attribute_search" => "quux" }])
    end

    teardown do
      FileUtils.remove_entry(@tmp_base_path)
    end

    test "initialize sets version to unstable by default" do
      command = GenerateDocsCommand.new({})
      assert_equal "unstable", command.instance_variable_get(:@version)
    end

    test "initialize accepts custom version" do
      command = GenerateDocsCommand.new(version: "2024-01")
      assert_equal "2024-01", command.instance_variable_get(:@version)
    end

    test "initialize raises error for invalid version format with special characters" do
      assert_raises(ArgumentError) do
        GenerateDocsCommand.new(version: "2024@01")
      end
    end

    test "initialize raises error for version containing double dots" do
      assert_raises(ArgumentError) do
        GenerateDocsCommand.new(version: "2024..01")
      end
    end

    test "run executes command and prints expected output for unstable version" do
      expected_output = <<~OUTPUT
        Version: unstable
        Generating sibling groups...
        Generating category search index...
        Generating attributes...
        Generating mappings...
        Generating attributes with categories...
        Generating attribute with categories search index...
        Completed in 0.1 seconds
      OUTPUT

      assert_output(expected_output) do
        Benchmark.stubs(:realtime).returns(0.1).yields
        GenerateDocsCommand.new({}).run
      end
    end

    test "run executes command and prints expected output for versioned release" do
      expected_output = <<~OUTPUT
        Version: 2024-01
        Generating sibling groups...
        Generating category search index...
        Generating attributes...
        Generating mappings...
        Generating attributes with categories...
        Generating attribute with categories search index...
        Generating release folder...
        Generating index.html...
        Generating attributes.html...
        Completed in 0.1 seconds
      OUTPUT

      assert_output(expected_output) do
        Benchmark.stubs(:realtime).returns(0.1).yields
        GenerateDocsCommand.new(version: "2024-01").run
      end
    end

    test "run suppresses non-error output when quiet is true" do
      assert_output("") do
        Benchmark.stubs(:realtime).returns(0.1).yields
        GenerateDocsCommand.new(quiet: true).run
      end
    end

    test "execute generates data files for unstable version" do
      command = GenerateDocsCommand.new({})
      command.execute

      data_path = File.expand_path("docs/_data/unstable", @tmp_base_path)

      assert File.exist?("#{data_path}/sibling_groups.yml")
      assert File.exist?("#{data_path}/search_index.json")
      assert File.exist?("#{data_path}/attributes.yml")
      assert File.exist?("#{data_path}/mappings.yml")
      assert File.exist?("#{data_path}/reversed_attributes.yml")
      assert File.exist?("#{data_path}/attribute_search_index.json")
      assert_equal "---\nsiblings: foo\n", File.read("#{data_path}/sibling_groups.yml")
      assert_equal "---\nattributes: baz\n", File.read("#{data_path}/attributes.yml")
      assert_equal "---\nreversed: qux\n", File.read("#{data_path}/reversed_attributes.yml")
      assert_equal '[{"search":"bar"}]' + "\n", File.read("#{data_path}/search_index.json")
      assert_equal '[{"attribute_search":"quux"}]' + "\n", File.read("#{data_path}/attribute_search_index.json")

      release_path = File.expand_path("docs/_releases/unstable", @tmp_base_path)
      refute File.exist?(release_path)
    end

    test "execute generates data files and release folder for versioned release" do
      command = GenerateDocsCommand.new(version: "2024-01")
      command.execute

      data_path = File.expand_path("docs/_data/2024-01", @tmp_base_path)

      assert File.exist?("#{data_path}/sibling_groups.yml")
      assert File.exist?("#{data_path}/search_index.json")
      assert File.exist?("#{data_path}/attributes.yml")
      assert File.exist?("#{data_path}/mappings.yml")
      assert File.exist?("#{data_path}/reversed_attributes.yml")
      assert File.exist?("#{data_path}/attribute_search_index.json")
      assert_equal "---\nsiblings: foo\n", File.read("#{data_path}/sibling_groups.yml")
      assert_equal "---\nattributes: baz\n", File.read("#{data_path}/attributes.yml")
      assert_equal "---\nreversed: qux\n", File.read("#{data_path}/reversed_attributes.yml")
      assert_equal '[{"search":"bar"}]' + "\n", File.read("#{data_path}/search_index.json")
      assert_equal '[{"attribute_search":"quux"}]' + "\n", File.read("#{data_path}/attribute_search_index.json")

      release_path = File.expand_path("docs/_releases/2024-01", @tmp_base_path)
      assert File.exist?("#{release_path}/index.html")
      assert File.exist?("#{release_path}/attributes.html")

      expected_index_content = <<~CONTENT
        ---
        layout: categories

        title: 2024-01
        target: 2024-01
        permalink: /releases/2024-01/
        github_url: https://github.com/Shopify/product-taxonomy/releases/tag/v2024-01
        include_in_release_list: true
        ---
      CONTENT
      assert_equal expected_index_content, File.read("#{release_path}/index.html")

      expected_attributes_content = <<~CONTENT
        ---
        layout: attributes

        title: 2024-01
        target: 2024-01
        permalink: /releases/2024-01/attributes/
        github_url: https://github.com/Shopify/product-taxonomy
        ---
      CONTENT
      assert_equal expected_attributes_content, File.read("#{release_path}/attributes.html")
    end

    test "reverse_shopify_mapping_rules correctly reverses mappings" do
      command = GenerateDocsCommand.new({})
      mappings = [{
        "input_taxonomy" => ["external"],
        "output_taxonomy" => ["shopify"],
        "rules" => [{
          "input" => { "category" => "test" },
          "output" => { "category" => ["mapped1", "mapped2"] },
        }],
      }]

      expected = [{
        "input_taxonomy" => ["shopify"],
        "output_taxonomy" => ["external"],
        "rules" => [
          {
            "input" => { "category" => "mapped1" },
            "output" => { "category" => ["test"] },
          },
          {
            "input" => { "category" => "mapped2" },
            "output" => { "category" => ["test"] },
          },
        ],
      }]

      assert_equal expected, command.send(:reverse_shopify_mapping_rules, mappings)
    end
  end
end
