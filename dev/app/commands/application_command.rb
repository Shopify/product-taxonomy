# frozen_string_literal: true

require "cli/ui"
require "tty-option"

class ApplicationCommand
  include TTY::Option
  include Loggable

  flag :verbose do
    desc "Run verbosely"
    short "-v"
    long "--verbose"
  end

  flag :quiet do
    desc "Run quietly"
    long "--quiet"
  end

  flag :force do
    desc "Overwrite files if they exist"
    short "-f"
    long "--force"
  end

  flag :help do
    desc "Print usage"
    short "-h"
    long  "--help"
  end

  class << self
    def run(argv = ARGV)
      new(argv:, interactive: true).run
    end
  end

  def initialize(argv: ARGV, interactive: false, **kwargs)
    @interactive = interactive

    parse(argv)
    params.merge!(kwargs)

    Loggable.log_level = :debug if params[:verbose]
    Loggable.log_level = :error if params[:quiet]

    @sys = System.new(force: params[:force])
    @null_spinner = NullSpinner.new(logger) unless interactive?
  end

  # Primary entry point for the command
  def run
    if params[:help]
      print(help)
      exit
    elsif params.errors.any?
      puts params.errors.summary
      exit(1)
    end

    if interactive?
      CLI::UI.frame_style = :bracket
      CLI::UI::StdoutRouter.enable
    end

    execute
  ensure
    CLI::UI::StdoutRouter.disable
  end

  # Invoke command without normal checks
  # Use when invoking from another command or in tests
  def execute
    raise NotImplementedError, "#{self.class}#execute must be implemented"
  end

  def interactive?
    @interactive
  end

  protected

  attr_reader :sys

  def frame(title, **kargs, &)
    if interactive?
      CLI::UI::Frame.open(title, **kargs, &)
    else
      logger.info(title)
      yield
    end
  end

  def spinner(title, **kwargs, &)
    if interactive?
      CLI::UI::Spinner.spin(title, **kwargs, &)
    else
      logger.info(title)
      yield(@null_spinner)
    end
  end

  class NullSpinner
    def initialize(logger)
      @logger = logger
    end

    def update_title(title)
      @logger.info(title)
    end
  end
end
