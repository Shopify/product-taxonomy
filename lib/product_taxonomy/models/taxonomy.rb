# frozen_string_literal: true

module ProductTaxonomy
  class Taxonomy
    include ActiveModel::Validations

    class << self
      def load_from_source(files: Dir.glob("data/categories/*.yml"))
        values = Value.load_from_source
        attributes = Attribute.load_from_source(values:)
        new(verticals: files.map { Category.load_from_source(attributes:, file: _1) })
      end
    end

    attr_reader :verticals

    validate :validate_verticals

    def initialize(verticals:)
      @verticals = verticals
    end

    def to_s
      verticals.map(&:to_s).join("\n")
    end

    def validate_verticals
      verticals.each do |vertical|
        unless vertical.valid?
          errors.add(:verticals, vertical.errors.full_messages.join("\n"))
        end
      end
    end

    def to_categories_json
      {
        version: ProductTaxonomy::VERSION,
        verticals: verticals.map do |vertical|
          {
            name: vertical.name,
            prefix: vertical.id,
            categories: traverse_categories(vertical).map do |category|
              {
                id: category.id,
                name: category.name,
                level: category.level,
                full_name: category.name,
                parent_id: category&.parent&.id,
                attributes: category.attributes.map do |attribute|
                  {
                    id: attribute.id,
                    name: attribute.name,
                    handle: attribute.handle,
                    extended: attribute.is_a?(ExtendedAttribute),
                  }
                end,
                children: category.children.map do |child|
                  {
                    id: child.id,
                    name: child.name,
                  }
                end,
                ancestors: category.ancestors.map do |ancestor|
                  {
                    id: ancestor.id,
                    name: ancestor.name,
                  }
                end,
              }
            end,
          }
        end,
      }
    end

    private

    def traverse_categories(category)
      result = [category]
      category.children.each do |child|
        result.concat(traverse_categories(child))
      end
      result
    end
  end
end
