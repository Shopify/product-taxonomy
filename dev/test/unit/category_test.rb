require_relative '../test_helper'
require_relative Application.from_src('/category')

class CategoryTest < Minitest::Test
  def test_initialize
    assert_equal 't', category.id
    assert_equal 'gid://shopify/Taxonomy/Category/t', category.gid
    assert_equal 'Electronics', category.name
    assert_equal 0, category.level
    assert_nil category.parent
    assert_empty category.children
    assert_empty category.attributes
  end

  def test_add_child
    child_category = Category.new(id: 't-2', name: 'Laptops')
    category.add(child_category)

    assert_equal category, child_category.parent
    assert_includes category.children, child_category
  end

  def test_find_category
    Category.new(id: 't-3', name: 'Smartphones')
    found_category = Category.find('t-3')

    assert_equal 'Smartphones', found_category.name
  end

  def test_find_category_not_found
    assert_nil Category.find('t-4')
  end

  def test_find_bang_category_not_found
    assert_raises(ArgumentError) { Category.find!('t-5') }
  end

  def test_root_category
    child_category = Category.new(id: 't-6', name: 'Child')
    category.add(child_category)

    assert_equal category, child_category.root
  end

  def test_ancestors
    child_category = Category.new(id: 't-7', name: 'Child')
    category.add(child_category)

    grandchild_category = Category.new(id: 't-7-1', name: 'Grandchild')
    child_category.add(grandchild_category)

    assert_equal Set[category, child_category], grandchild_category.ancestors
  end

  def test_descendants
    child_category = Category.new(id: 't-8', name: 'Child')
    category.add(child_category)

    grandchild_category = Category.new(id: 't-8-1', name: 'Grandchild')
    child_category.add(grandchild_category)

    assert_equal Set[child_category, grandchild_category], category.descendants
  end

  def test_comparison
    category1 = Category.new(id: 't-13', name: 'Category 1')
    category2 = Category.new(id: 't-14', name: 'Category 2')

    assert_equal (-1), category1 <=> category2
    assert_equal 1, category2 <=> category1
    assert_equal 0, category1 <=> category1
  end

  private

  def category
    @category ||= Category.new(id: 't', name: 'Electronics')
  end
end
