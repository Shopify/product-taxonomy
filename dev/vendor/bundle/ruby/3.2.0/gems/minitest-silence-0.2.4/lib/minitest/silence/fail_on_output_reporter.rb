# frozen_string_literal: true

module Minitest
  module Silence
    class FailOnOutputReporter < Minitest::Reporter
      def record(result)
        unless result.output.empty?
          assertion = Minitest::Assertion.new(<<~EOM.chomp)
            The test unexpectedly wrote output to STDOUT or STDERR.

            #{Minitest::Silence.boxed('Output', result.output)}
          EOM
          assertion.set_backtrace(caller)
          result.failures << assertion
        end
      end
    end
  end
end
