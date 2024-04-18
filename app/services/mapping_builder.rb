# frozen_string_literal: true

class MappingBuilder
  class << self
    def simple_mapping(mapping_rules:)
      mapping_rules
        .map do
          {
            input: _1.input.payload.compact,
            output: _1.output.payload.compact,
          }
        end
    end
  end
end
