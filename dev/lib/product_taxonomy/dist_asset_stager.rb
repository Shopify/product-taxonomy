# frozen_string_literal: true

require "fileutils"
require "zlib"

module ProductTaxonomy
  class DistAssetStager
    ALLOWED_ROOT_FILES = ["README.md"].freeze
    DATA_EXTENSIONS = [".json", ".txt"].freeze
    LOCALE_PATTERN = /\A[a-z]{2,3}(?:-[A-Z]{2})?\z/

    def initialize(input_path:, output_path:)
      @input_path = File.expand_path(input_path)
      @output_path = File.expand_path(output_path)
    end

    def stage
      validate_paths!
      staging_plan = build_staging_plan
      validate_collisions!(staging_plan)

      FileUtils.rm_rf(@output_path)
      FileUtils.mkdir_p(@output_path)

      staging_plan.map do |source_path, asset_name|
        destination_path = File.join(@output_path, asset_name)
        gzip_file(source_path, destination_path)
        destination_path
      end
    end

    private

    def validate_paths!
      raise ArgumentError, "Input path does not exist: #{@input_path}" unless File.directory?(@input_path)

      paths_overlap = @output_path == @input_path ||
        @output_path.start_with?("#{@input_path}#{File::SEPARATOR}") ||
        @input_path.start_with?("#{@output_path}#{File::SEPARATOR}")
      raise ArgumentError, "Input and output paths must not overlap" if paths_overlap

      root_entries = Dir.children(@input_path).sort
      unexpected_files = root_entries.reject do |entry|
        path = File.join(@input_path, entry)
        File.directory?(path) || (ALLOWED_ROOT_FILES.include?(entry) && File.file?(path))
      end
      unless unexpected_files.empty?
        raise ArgumentError, "Unexpected files at distribution root: #{unexpected_files.join(", ")}"
      end

      unexpected_directories = root_entries.select do |entry|
        File.directory?(File.join(@input_path, entry)) && !entry.match?(LOCALE_PATTERN)
      end
      return if unexpected_directories.empty?

      raise ArgumentError, "Unexpected directories at distribution root: #{unexpected_directories.join(", ")}"
    end

    def build_staging_plan
      locale_directories.flat_map do |locale_directory|
        locale = File.basename(locale_directory)
        data_files(locale_directory).map do |source_path|
          [source_path, asset_name(source_path, locale_directory, locale)]
        end
      end.sort_by(&:last)
    end

    def locale_directories
      Dir.children(@input_path).sort.filter_map do |entry|
        path = File.join(@input_path, entry)
        path if File.directory?(path)
      end
    end

    def data_files(locale_directory)
      files = Dir.glob(File.join(locale_directory, "**", "*"), File::FNM_DOTMATCH).select { File.file?(_1) }.sort
      unexpected_files = files.reject { DATA_EXTENSIONS.include?(File.extname(_1)) }
      unless unexpected_files.empty?
        relative_paths = unexpected_files.map { _1.delete_prefix("#{@input_path}#{File::SEPARATOR}") }
        raise ArgumentError, "Unexpected files in locale directories: #{relative_paths.join(", ")}"
      end

      files
    end

    def asset_name(source_path, locale_directory, locale)
      relative_path = source_path.delete_prefix("#{locale_directory}#{File::SEPARATOR}")
      extension = File.extname(relative_path)
      basename = File.basename(relative_path, extension)
      relative_directory = File.dirname(relative_path)
      directory_parts = relative_directory == "." ? [] : relative_directory.split(File::SEPARATOR)

      [*directory_parts, basename, locale].join(".") + extension + ".gz"
    end

    def gzip_file(source_path, destination_path)
      Zlib::GzipWriter.open(destination_path) do |gzip_writer|
        gzip_writer.mtime = 0
        File.open(source_path, "rb") { IO.copy_stream(_1, gzip_writer) }
      end
    end

    def validate_collisions!(staging_plan)
      collisions = staging_plan.group_by(&:last).select { |_, sources| sources.length > 1 }
      return if collisions.empty?

      details = collisions.sort.map do |asset_name, sources|
        source_paths = sources.map(&:first).join(", ")
        "#{asset_name} (#{source_paths})"
      end
      raise ArgumentError, "Distribution asset naming collision: #{details.join("; ")}"
    end
  end
end
