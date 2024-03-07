require_relative '../test_helper'

class CategoryTest < Minitest::Test
  def teardown
    Category.destroy_all
  end

  def test_root_category
    child_category = Category.new(id: 'tt-6', name: 'Child')
    category.children << child_category

    assert_equal category, child_category.root
  end

  def test_id_validations
    assert_predicate Category.new(id: 'tt', name: 'Root'), :valid?
    assert_predicate Category.new(id: 'tt-0', name: 'Child', parent: category), :valid?
    assert_predicate Category.new(id: 'tt-123232', name: 'Big child', parent: category), :valid?

    assert_predicate Category.new(id: 't', name: 'Root too short'), :invalid?
    assert_predicate Category.new(id: 'ttt', name: 'Root too long'), :invalid?
    assert_predicate Category.new(id: '01', name: 'Root of numbers'), :invalid?
    assert_predicate Category.new(id: 'tt-t', name: 'Child of letters', parent: category), :invalid?
    assert_predicate Category.new(id: 'tt-1234567890-26', name: 'Too deep', parent: category), :invalid?
  end

  def test_parent_validations
    valid_child = Category.new(id: 'tt-7', name: 'Valid Child', parent: category)
    valid_grandchild = Category.new(id: 'tt-7-1', name: 'Valid Grandchild', parent: valid_child)

    assert_predicate valid_child, :valid?
    assert_predicate valid_grandchild, :valid?

    invalid_child = Category.new(id: 'ff', name: 'Invalid Child', parent: category)
    invalid_grandchild = Category.new(id: 'tt-6-1', name: 'Invalid Grandchild', parent: valid_child)

    assert_predicate invalid_child, :invalid?
    assert_predicate invalid_grandchild, :invalid?
  end

  def test_ancestors_are_ordered
    child_category = Category.new(id: 'tt-7', name: 'Child')
    category.children << child_category

    grandchild_category = Category.new(id: 'tt-7-1', name: 'Grandchild')
    child_category.children << grandchild_category

    assert_equal [child_category, category], grandchild_category.ancestors
  end

  def test_ancestors_and_self_includes_self
    child_category = Category.new(id: 'tt-7', name: 'Child')
    category.children << child_category

    grandchild_category = Category.new(id: 'tt-7-1', name: 'Grandchild')
    child_category.children << grandchild_category

    assert_equal [grandchild_category, child_category, category], grandchild_category.ancestors_and_self
  end

  def test_descendants_are_depth_first
    l2_category = Category.new(id: 'tt-8', name: 'Child')
    category.children << l2_category

    l3_category = Category.new(id: 'tt-8-1', name: 'Grandchild')
    l2_category.children << l3_category

    l3_sibling = Category.new(id: 'tt-8-2', name: 'Alpha Grandchild')
    l2_category.children << l3_sibling

    l4_category = Category.new(id: 'tt-8-1-1', name: 'Great Grandchild')
    l3_sibling.children << l4_category

    assert_equal [l2_category, l3_sibling, l4_category, l3_category], category.descendants
  end

  def test_descendants_and_self_includes_self
    child_category = Category.create(id: 'tt-7', name: 'Child')
    category.children << child_category

    grandchild_category = Category.create(id: 'tt-7-1', name: 'Grandchild')
    child_category.children << grandchild_category

    assert_equal [category, child_category, grandchild_category], category.descendants_and_self.to_a
  end

  private

  def category
    @category ||= Category.create!(id: 'tt', name: 'Electronics')
  end
end
