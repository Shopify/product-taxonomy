# frozen_string_literal: true

require "fileutils"
require "json"
require "optparse"
require "yaml"

class CLI
  ROOT = File.expand_path("..", __dir__)
  private_constant :ROOT

  class << self
    def root
      @root ||= Pathname.new(ROOT)
    end

    def path(path_from_root)
      root.join(path_from_root).relative_path_from(Pathname.pwd)
    end
  end

  attr_reader :options

  def initialize(options = [], &parser_options)
    @options = Struct.new(*options, :verbose, :force).new
    @options.verbose = false
    @options.force = false

    @parser = OptionParser.new(&parser_options)
    @parser.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
    @parser.on("-v", "--[no-]verbose", "Run verbosely")
    @parser.on("-f", "--force", "Overwrite files if they exist")
    @parser.on_tail("-h", "--help", "Prints this help") do
      puts @parser
      exit
    end
  end

  def parse!(input)
    @parser.parse!(input, into: options)
  end

  def options_status
    vputs("Options: #{options.to_h}")
  end

  def vputs(...)
    puts(...) if options.verbose
  end

  def read_file(path_from_root)
    path = path_for(path_from_root)
    vputs("→ Reading `#{path}`")

    File.read(path)
  end

  def glob(path_from_root)
    path = path_for(path_from_root)
    vputs("→ Globbing `#{path}`")

    Dir.glob(path)
  end

  def parse_json(path_from_root)
    JSON.parse(read_file(path_from_root))
  end

  def parse_yaml(path_from_root)
    YAML.load(read_file(path_from_root))
  end

  def write_file(path_from_root, &)
    path = path_for(path_from_root)
    if new_or_forced?(path)
      write_file!(path, &)
    else
      vputs("→ Skipping `#{path}`")
    end
  end

  def write_file!(path_from_root, &)
    path = path_for(path_from_root)
    vputs("→ Writing `#{path}`")

    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, "w", &)
  end

  private

  def new_or_forced?(path_from_root)
    options.force || !File.exist?(path_for(path_from_root))
  end

  def path_for(from_root_or_path)
    case from_root_or_path
    when Pathname
      from_root_or_path
    else
      self.class.path(from_root_or_path)
    end
  end
end
