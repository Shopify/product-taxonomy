require_relative 'category'

class Taxonomy
  attr_reader :verticals, :attributes

  def initialize(vertical_data:, attribute_data:)
    @attributes = attribute_data
    attribute_names_by_id = attributes.map { [_1["id"], _1["name"]] }.to_h

    @verticals = vertical_data.map do |_, categories|
      categories.map { |category| Category.from_json(category, attribute_names_by_id) }
    end
  end

  def categories
    @categories ||= verticals.flatten
  end
end
