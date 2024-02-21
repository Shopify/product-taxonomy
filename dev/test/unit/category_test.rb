require_relative '../test_helper'

class CategoryTest < Minitest::Test
  def teardown
    Category.destroy_all
  end

  def test_root_category
    child_category = Category.new(id: 't-6', name: 'Child')
    category.children << child_category

    assert_equal category, child_category.root
  end

  def test_ancestors_are_ordered
    child_category = Category.new(id: 't-7', name: 'Child')
    category.children << child_category

    grandchild_category = Category.new(id: 't-7-1', name: 'Grandchild')
    child_category.children << grandchild_category

    assert_equal [child_category, category], grandchild_category.ancestors
  end

  def test_ancestors_and_self_includes_self
    child_category = Category.new(id: 't-7', name: 'Child')
    category.children << child_category

    grandchild_category = Category.new(id: 't-7-1', name: 'Grandchild')
    child_category.children << grandchild_category

    assert_equal [grandchild_category, child_category, category], grandchild_category.ancestors_and_self
  end

  def test_descendants_are_depth_first
    l2_category = Category.new(id: 't-8', name: 'Child')
    category.children << l2_category

    l3_category = Category.new(id: 't-8-1', name: 'Grandchild')
    l2_category.children << l3_category

    l3_sibling = Category.new(id: 't-8-2', name: 'Alpha Grandchild')
    l2_category.children << l3_sibling

    l4_category = Category.new(id: 't-8-1-1', name: 'Great Grandchild')
    l3_sibling.children << l4_category

    assert_equal [l2_category, l3_sibling, l4_category, l3_category], category.descendants
  end

  def test_descendants_and_self_includes_self
    child_category = Category.create(id: 't-7', name: 'Child')
    category.children << child_category

    grandchild_category = Category.create(id: 't-7-1', name: 'Grandchild')
    child_category.children << grandchild_category

    assert_equal [category, child_category, grandchild_category], category.descendants_and_self.to_a
  end

  private

  def category
    @category ||= Category.create!(id: 't', name: 'Electronics')
  end
end
