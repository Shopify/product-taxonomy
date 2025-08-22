# frozen_string_literal: true

require "minitest/silence/fail_on_output_reporter"
require "minitest/silence/boxed_output_reporter"
require "minitest/silence/version"
require "io/console"

module Minitest
  module Silence
    Error = Class.new(StandardError)
    UnexpectedOutput = Class.new(Error)

    module ResultOutputPatch
      attr_accessor :output
    end

    module RunOneMethodPatch
      def run_one_method(klass, method_name)
        @original_stdin ||= $stdin.dup
        @original_stdout ||= $stdout.dup
        @original_stderr ||= $stderr.dup

        output_reader, output_writer = IO.pipe
        output_thread = Thread.new { output_reader.read }

        result = begin
          $stdout.reopen(output_writer)
          $stderr.reopen(output_writer)
          $stdin.reopen(File::NULL)

          super
        ensure
          $stdout.reopen(@original_stdout)
          $stderr.reopen(@original_stderr)
          $stdin.reopen(@original_stdin)
          output_writer.close
        end

        result.output = output_thread.value
        result
      ensure
        output_reader.close
      end
    end

    class << self
      def boxed(title, content)
        box = +"── #{title} ──\n"
        box << "#{content}\n"
        box << "───#{'─' * title.length}───\n"
      end
    end
  end

  class << self
    def plugin_silence_options(opts, options)
      opts.on('--enable-silence', "Rebind standard IO") do
        options[:enable_silence] = true
      end
      opts.on('--fail-on-output', "Fail a test when it writes to STDOUT or STDERR") do
        options[:fail_on_output] = true
      end
    end

    def plugin_silence_init(options)
      if options[:enable_silence] || ENV["CI"]
        Minitest::Result.prepend(Minitest::Silence::ResultOutputPatch)
        Minitest.singleton_class.prepend(Minitest::Silence::RunOneMethodPatch)

        if options[:fail_on_output]
          # We have to make sure this reporter runs as the first reporter, so it can still adjust
          # the result and other reporters will take the change into account.
          reporter.reporters.unshift(Minitest::Silence::FailOnOutputReporter.new(options[:io], options))
        elsif options[:verbose]
          reporter << Minitest::Silence::BoxedOutputReporter.new(options[:io], options)
        end
      end
    end
  end
end
