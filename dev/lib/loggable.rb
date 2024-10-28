# frozen_string_literal: true

require "cli/ui"

module Loggable
  class CLIUILogger
    LEVELS = [:debug, :info, :warn, :error, :fatal]

    def initialize
      @level = :info
    end

    LEVELS.each do |level|
      define_method(level) do |message|
        log(level, message) if should_log?(level)
      end
    end

    def success(message)
      CLI::UI.puts(CLI::UI.fmt("{{v}} #{message}")) if should_log?(:info)
    end

    def headline(message)
      CLI::UI.puts(CLI::UI.fmt("{{*}} #{message}")) if should_log?(:info)
    end

    def level=(new_level)
      @level = new_level if LEVELS.include?(new_level)
    end

    private

    def should_log?(message_level)
      LEVELS.index(message_level) >= LEVELS.index(@level)
    end

    def log(level, message)
      color = case level
      when :debug then "blue"
      when :info then "green"
      when :warn then "yellow"
      when :error, :fatal then "red"
      end

      CLI::UI.puts(CLI::UI.fmt("[{{#{color}:#{level.upcase}}}] #{message}"))
    end
  end

  @logger = CLIUILogger.new

  class << self
    attr_reader :logger

    def log_level=(level)
      @logger.level = level
    end
  end

  def logger
    Loggable.logger
  end
end
