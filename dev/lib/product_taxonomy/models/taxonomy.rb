# frozen_string_literal: true

module ProductTaxonomy
  class Taxonomy
    attr_reader :verticals

    def initialize(verticals:)
      @verticals = verticals
    end
  end
end
