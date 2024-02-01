require_relative 'category'
require_relative 'attribute'
require_relative 'attribute_value'

require_relative 'storage/memory'

class Taxonomy
  attr_reader :verticals, :attributes

  def initialize(vertical_data:, attribute_data:)
    @attributes = attribute_data.map { Attribute.from_json(_1) }
    @verticals = vertical_data.map do |vertical|
      vertical.map { Category.from_json(_1) }
    end
  end

  def categories
    @categories ||= verticals.flatten
  end
end
