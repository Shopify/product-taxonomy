require_relative '../test_helper'

class PropertyValueTest < Minitest::Test
  def teardown
    PropertyValue.destroy_all
  end

  def test_gid
    assert_equal 'gid://shopify/Taxonomy/Value/12', value(id: 12).gid
  end

  def test_default_ordering_places_other_at_end
    red = value!(id: 11, name: 'Red')
    zoo = value!(id: 12, name: 'Zoo')
    other = value!(id: 13, name: 'Other')

    assert_equal [red, zoo, other], PropertyValue.all.to_a
  end

  private

  def value(id: 1, name: 'Foo')
    PropertyValue.new(id: id, name: name)
  end

  def value!(id: 1, name: 'Foo')
    PropertyValue.create(id: id, name: name)
  end
end
