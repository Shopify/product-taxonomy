# frozen_string_literal: true

module Minitest
  module Silence
    class BoxedOutputReporter < Minitest::Reporter
      def record(result)
        unless result.output.empty?
          io.puts(Minitest::Silence.boxed("Output from #{result.class_name}##{result.name}", result.output))
          io.puts
        end
      end
    end
  end
end
