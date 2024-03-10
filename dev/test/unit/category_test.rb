require_relative '../test_helper'

class CategoryTest < ActiveSupport::TestCase
  def teardown
    Category.destroy_all
  end

  test "#id must follow parent" do
    assert_predicate Category.new(id: 'tt', name: 'Root'), :valid?
    assert_predicate Category.new(id: 'tt-0', name: 'Child', parent: category), :valid?
    assert_predicate Category.new(id: 'tt-123232', name: 'Big child', parent: category), :valid?

    assert_predicate Category.new(id: 'aa-0', name: 'Child', parent: category), :invalid?

    child = Category.new(id: 'tt-0', name: 'Child', parent: category)
    assert_predicate Category.new(id: 'tt-1-1', name: 'Child', parent: child), :invalid?
  end

  test "#id must follow a strict format" do
    assert_predicate Category.new(id: 't', name: 'Root too short'), :invalid?
    assert_predicate Category.new(id: 'ttt', name: 'Root too long'), :invalid?
    assert_predicate Category.new(id: '01', name: 'Root of numbers'), :invalid?
    assert_predicate Category.new(id: 'tt-t', name: 'Child of letters', parent: category), :invalid?
  end

  test "#id must match depth" do
    assert_predicate Category.new(id: 'tt-0', name: 'Child', parent: category), :valid?

    assert_predicate Category.new(id: 'tt-0-1', name: 'Child with grandchild ID', parent: category), :invalid?
  end

  test "#gid returns a global id" do
    assert_equal "gid://shopify/Taxonomy/Category/tt", category.gid
  end

  test "#root returns the top-most category node" do
    child_category = Category.new(id: 'tt-6', name: 'Child', parent: category)
    grandchild_category = Category.new(id: 'tt-6-1', name: 'Grandchild', parent: child_category)

    assert_equal category, child_category.root
    assert_equal category, grandchild_category.root
  end

  test "#ancestors walk up the tree" do
    child_category = Category.new(id: 'tt-7', name: 'Child', parent: category)
    grandchild_category = Category.new(id: 'tt-7-1', name: 'Grandchild', parent: child_category)
    category.reload

    assert_equal [child_category, category], grandchild_category.ancestors
  end

  test "#ancestors_and_self includes self" do
    child_category = Category.create(id: 'tt-7', name: 'Child', parent: category)
    grandchild_category = Category.new(id: 'tt-7-1', name: 'Grandchild', parent: child_category)
    category.reload

    assert_equal [grandchild_category, child_category, category], grandchild_category.ancestors_and_self
  end

  test "#children are sorted by name" do
    beta_child = Category.create(id: 'tt-1', name: 'Beta', parent: category)
    alpha_child = Category.create(id: 'tt-2', name: 'Alpha', parent: category)
    category.reload

    assert_equal [alpha_child, beta_child], category.children.to_a
  end

  test "#descendants is depth-first" do
    l2_category = Category.create(id: 'tt-8', name: 'Child', parent: category)
    l3_category = Category.create(id: 'tt-8-1', name: 'Grandchild', parent: l2_category)
    l3_sibling = Category.create(id: 'tt-8-2', name: 'Alpha Grandchild', parent: l2_category)
    l4_category = Category.create(id: 'tt-8-2-1', name: 'Great Grandchild', parent: l3_sibling)
    category.reload

    assert_equal [l2_category, l3_sibling, l4_category, l3_category], category.descendants
  end

  test "#descendants_and_self includes self" do
    child_category = Category.create(id: 'tt-7', name: 'Child', parent: category)
    grandchild_category = Category.create(id: 'tt-7-1', name: 'Grandchild', parent: child_category)
    category.reload

    assert_equal [category, child_category, grandchild_category], category.descendants_and_self
  end

  private

  def category
    @category ||= Category.create!(id: 'tt', name: 'Electronics')
  end
end
