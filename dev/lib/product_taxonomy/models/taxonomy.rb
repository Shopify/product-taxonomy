# typed: strict
# frozen_string_literal: true

module ProductTaxonomy
  class Taxonomy
    extend T::Sig

    sig { params(verticals: T::Array[Category]).void }
    def initialize(verticals:)
      @verticals = verticals
    end
  end
end
