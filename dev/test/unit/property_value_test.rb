require_relative '../test_helper'

class PropertyValueTest < Minitest::Test
  def teardown
    PropertyValue.destroy_all
  end

  def test_gid
    assert_equal 'gid://shopify/Taxonomy/Value/12', PropertyValue.new(id: 12, name: 'Foo', friendly_id: 'foo').gid
  end

  def test_default_ordering_places_other_at_end
    red = PropertyValue.create(id: 11, name: 'Red', friendly_id: 'red')
    zoo = PropertyValue.create(id: 12, name: 'Zoo', friendly_id: 'zoo')
    other = PropertyValue.create(id: 13, name: 'Other', friendly_id: 'other')

    assert_equal [red, zoo, other], PropertyValue.all.to_a
  end
end
