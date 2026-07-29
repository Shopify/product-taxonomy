# frozen_string_literal: true

require "open3"

module ProductTaxonomy
  class CommandExecutor
    DEFAULT_RUNNER = Open3.method(:capture3)

    def initialize(command_runner: DEFAULT_RUNNER)
      @command_runner = command_runner
    end

    def run!(*command, chdir:, failure_message:)
      stdout, stderr, status = capture(*command, chdir:, failure_message:)
      return stdout if status.success?

      details = stderr.strip
      details = stdout.strip if details.empty?
      message = details.empty? ? failure_message : "#{failure_message} #{details}"
      raise message
    end

    def capture(*command, chdir:, failure_message:)
      @command_runner.call(*command, chdir:)
    rescue SystemCallError => error
      raise "#{failure_message} #{error.message}"
    end
  end
end
