# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "zlib"

module ProductTaxonomy
  class DistAssetStagerTest < TestCase
    setup do
      @temporary_directory = Dir.mktmpdir
      @input_path = File.join(@temporary_directory, "dist")
      @output_path = File.join(@temporary_directory, "release-assets")
      FileUtils.mkdir_p(@input_path)
    end

    teardown do
      FileUtils.remove_entry(@temporary_directory)
    end

    test "#stage gzip-compresses a simple locale file with deterministic metadata and excludes the README" do
      write_dist_file("en/categories.json", "categories")
      write_dist_file("README.md", "documentation")

      staged_files = stager.stage
      asset_path = File.join(@output_path, "categories.en.json.gz")

      assert_equal(["categories.en.json.gz"], staged_files.map { File.basename(_1) })
      Zlib::GzipReader.open(asset_path) do |gzip_reader|
        assert_equal(0, gzip_reader.mtime.to_i)
        assert_equal("categories", gzip_reader.read)
      end
      refute_path_exists(File.join(@output_path, "README.md.gz"))
    end

    test "#stage adds each locale to compressed files with the same relative path" do
      write_dist_file("fr/taxonomy.json", "French")
      write_dist_file("en/taxonomy.json", "English")

      staged_files = stager.stage

      assert_equal(["taxonomy.en.json.gz", "taxonomy.fr.json.gz"], staged_files.map { File.basename(_1) })
      assert_equal("English", read_gzip("taxonomy.en.json.gz"))
      assert_equal("French", read_gzip("taxonomy.fr.json.gz"))
    end

    test "#stage flattens nested integration directories into dot-separated asset names" do
      write_dist_file("en/integrations/all_mappings.json", "all mappings")
      mapping_name = "shopify_2021-01_to_shopify_2025-01"
      write_dist_file("en/integrations/shopify/#{mapping_name}.json", "Shopify mapping")

      staged_files = stager.stage

      assert_equal(
        [
          "integrations.all_mappings.en.json.gz",
          "integrations.shopify.#{mapping_name}.en.json.gz",
        ],
        staged_files.map { File.basename(_1) },
      )
    end

    test "#stage removes stale output before copying assets" do
      FileUtils.mkdir_p(@output_path)
      File.write(File.join(@output_path, "stale.json"), "stale")
      write_dist_file("en/categories.json", "categories")

      stager.stage

      assert_equal(["categories.en.json.gz"], Dir.children(@output_path))
    end

    test "#stage returns the same sorted byte-identical gzip files regardless of input creation order" do
      write_dist_file("fr/taxonomy.txt", "French")
      write_dist_file("en/integrations/all_mappings.json", "mappings")
      write_dist_file("en/categories.json", "categories")

      first_staged_files = stager.stage
      first_contents = first_staged_files.to_h { [File.basename(_1), File.binread(_1)] }
      second_staged_files = stager.stage
      second_contents = second_staged_files.to_h { [File.basename(_1), File.binread(_1)] }

      expected_file_list = [
        "categories.en.json.gz",
        "integrations.all_mappings.en.json.gz",
        "taxonomy.fr.txt.gz",
      ]
      assert_equal(expected_file_list, first_contents.keys)
      assert_equal(first_contents, second_contents)
      assert_equal("French", read_gzip("taxonomy.fr.txt.gz"))
    end

    test "#stage raises without deleting input when the input path is inside the output path" do
      source_path = File.join(@input_path, "en", "categories.json")
      write_dist_file("en/categories.json", "categories")
      @output_path = @temporary_directory

      error = assert_raises(ArgumentError) { stager.stage }

      assert_equal("Input and output paths must not overlap", error.message)
      assert_path_exists(source_path)
    end

    test "#stage raises when different relative paths produce the same asset name" do
      write_dist_file("en/integrations/all_mappings.json", "nested")
      write_dist_file("en/integrations.all_mappings.json", "flat")

      error = assert_raises(ArgumentError) { stager.stage }

      assert_includes(error.message, "Distribution asset naming collision")
      assert_includes(error.message, "integrations.all_mappings.en.json.gz")
    end

    test "#stage raises when the distribution root contains an unexpected file" do
      write_dist_file("en/categories.json", "categories")
      write_dist_file("manifest.json", "unexpected")

      error = assert_raises(ArgumentError) { stager.stage }

      assert_equal("Unexpected files at distribution root: manifest.json", error.message)
    end

    test "#stage raises when a root directory is not locale-shaped" do
      write_dist_file("en/categories.json", "categories")
      write_dist_file("assets/logo.svg", "logo")

      error = assert_raises(ArgumentError) { stager.stage }

      assert_equal("Unexpected directories at distribution root: assets", error.message)
    end

    test "#stage raises when a locale directory contains a non-data file" do
      write_dist_file("en/categories.json", "categories")
      write_dist_file("en/.DS_Store", "metadata")

      error = assert_raises(ArgumentError) { stager.stage }

      assert_equal("Unexpected files in locale directories: en/.DS_Store", error.message)
    end

    private

    def stager
      DistAssetStager.new(input_path: @input_path, output_path: @output_path)
    end

    def write_dist_file(relative_path, content)
      path = File.join(@input_path, relative_path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end

    def read_gzip(asset_name)
      Zlib::GzipReader.open(File.join(@output_path, asset_name), &:read)
    end
  end
end
