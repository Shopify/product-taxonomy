require_relative 'category'
require_relative 'attribute'
require_relative 'attribute_value'

require_relative 'storage/memory'

class Taxonomy
  attr_reader :verticals, :attributes

  def initialize(vertical_data:, attribute_data:)
    @attributes = attribute_data.map { Attribute.from_json(_1) }
    @verticals = vertical_data.map do |vertical|
      # load data into memory
      vertical.each { Category.from_json(_1) }

      Category.find!(vertical.first["id"]).root
    end
  end

  def all_categories
    @categories ||= verticals.flat_map(&:descendants_and_self)
  end
end
