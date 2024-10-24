# frozen_string_literal: true

require "psych"

module YamlSerializer
  class << self
    def dump(object)
      ast = Psych.parse_stream(object.to_yaml(line_width: -1))

      # First pass, quote everything
      ast.grep(Psych::Nodes::Scalar).each do |node|
        node.plain  = false
        node.quoted = true
        node.style  = Psych::Nodes::Scalar::DOUBLE_QUOTED
      end

      # Second pass, unquote keys
      ast.grep(Psych::Nodes::Mapping).each do |node|
        node.children.each_slice(2) do |k, _|
          k.plain  = true
          k.quoted = false
          k.style  = Psych::Nodes::Scalar::ANY
        end
      end

      # Third pass, unquote integers
      ast.grep(Psych::Nodes::Scalar).each do |node|
        if integer_string?(node.value)
          node.plain  = true
          node.quoted = false
          node.style  = Psych::Nodes::Scalar::ANY
        end
      end

      ast.yaml
    end

    private

    def integer_string?(str)
      Integer(str)
      true
    rescue ArgumentError, TypeError
      false
    end
  end
end
