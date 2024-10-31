# frozen_string_literal: true

module ProductTaxonomy
  class Taxonomy
    class << self
      def load_from_source(files: Dir.glob("data/categories/*.yml"))
        values = Value.load_from_source
        attributes = Attribute.load_from_source(values:)
        new(verticals: files.map { Category.load_from_source(attributes:, file: _1) })
      end
    end

    attr_reader :verticals

    def initialize(verticals:)
      @verticals = verticals
    end

    def to_s
      verticals.map(&:to_s).join("\n")
    end
  end
end
