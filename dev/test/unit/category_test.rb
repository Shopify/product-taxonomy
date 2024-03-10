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

  def test_children_sort_by_name
    beta_child = Category.create(id: 'tt-1', name: 'Beta', parent: category)
    alpha_child = Category.create(id: 'tt-2', name: 'Alpha', parent: category)

    assert_equal [alpha_child, beta_child], category.reload.children.to_a
  end

  def test_ancestors_and_self_includes_self
    child_category = Category.new(id: 'tt-7', name: 'Child')
    category.children << child_category

    grandchild_category = Category.new(id: 'tt-7-1', name: 'Grandchild')
    child_category.children << grandchild_category

    assert_equal [grandchild_category, child_category, category], grandchild_category.ancestors_and_self
  end

  def test_descendants_are_depth_first
    l2_category = Category.create(id: 'tt-8', name: 'Child', parent: category)
    l3_category = Category.create(id: 'tt-8-1', name: 'Grandchild', parent: l2_category)
    l3_sibling = Category.create(id: 'tt-8-2', name: 'Alpha Grandchild', parent: l2_category)
    l4_category = Category.create(id: 'tt-8-2-1', name: 'Great Grandchild', parent: l3_sibling)

    assert_equal [l2_category, l3_sibling, l4_category, l3_category], category.reload.descendants
  end

  def test_descendants_and_self_includes_self
    child_category = Category.create(id: 'tt-7', name: 'Child')
    category.children << child_category

    grandchild_category = Category.create(id: 'tt-7-1', name: 'Grandchild')
    child_category.children << grandchild_category

    assert_equal [category, child_category, grandchild_category], category.descendants_and_self
  end

  private

  def category
    @category ||= Category.create!(id: 'tt', name: 'Electronics')
  end
end
