# frozen_string_literal: true

require "fileutils"
require "json"
require "optparse"
require "yaml"

# TODO: Rename to ??? to avoid collision with `system` method
class System
  include Loggable

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

  attr_reader :force

  def initialize(force: false)
    @force = force
  end

  def read_file(path_from_root)
    path = path_for(path_from_root)
    logger.debug("→ Reading `#{path}`")

    File.read(path)
  end

  def glob(path_from_root)
    path = path_for(path_from_root)
    logger.debug("→ Globbing `#{path}`")

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
      logger.debug("→ Skipping `#{path}`")
    end
  end

  def write_file!(path_from_root, &file_block)
    path = path_for(path_from_root)
    logger.debug("→ Writing `#{path}`")

    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, "w", &file_block)
    logger.success("Wrote `#{path}`")
  end

  def move_file!(target_from_root, new_path_from_root)
    target = path_for(target_from_root)
    path = path_for(new_path_from_root)
    logger.debug("→ Moving `#{target}` to `#{path}`")

    FileUtils.mkdir_p(File.dirname(path))
    File.rename(target, path)
    logger.success("Moved `#{target}` to `#{path}`")
  end

  private

  def new_or_forced?(path_from_root)
    force || !File.exist?(path_for(path_from_root))
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
