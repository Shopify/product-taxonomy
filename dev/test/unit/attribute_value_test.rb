require_relative '../test_helper'
require_relative Application.from_src('attribute_value')

class AttributeValueTest < Minitest::Test
  def test_gid
    assert_equal 'gid://shopify/Taxonomy/Attribute/1/1', AttributeValue.new(id: '1-1', name: 'Foo').gid
  end

  def test_comparison_is_by_name
    red = AttributeValue.new(id: '1-1', name: 'Red')
    blue = AttributeValue.new(id: '1-2', name: 'Blue')

    assert_equal (-1), blue <=> red
    assert_equal 0, red <=> red
    assert_equal 1, red <=> blue
  end

  def test_comparison_places_other_at_end
    red = AttributeValue.new(id: '1-1', name: 'Red')
    zoo = AttributeValue.new(id: '1-2', name: 'Zoo')
    other = AttributeValue.new(id: '1-3', name: 'Other')

    assert_equal [red, zoo, other], [other, red, zoo].sort
  end
end
