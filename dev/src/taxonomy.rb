require_relative 'category'
require_relative 'attribute'
require_relative 'attribute_value'

class Taxonomy
  attr_reader :verticals, :attributes

  def initialize(vertical_data:, attribute_data:)
    @attributes = attribute_data.map { Attribute.from_json(_1) }
    attribute_names_by_id = attributes.map { [_1.id, _1.name] }.to_h

    @verticals = vertical_data.map do |_, categories|
      categories.map { Category.from_json(_1, attribute_names_by_id) }
    end
  end

  def categories
    @categories ||= verticals.flatten
  end
end
