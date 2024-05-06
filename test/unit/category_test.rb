# frozen_string_literal: true

require_relative "../test_helper"

class CategoryTest < ApplicationTestCase
  def teardown
    Category.delete_all
  end

  test ".gid returns a global id" do
    assert_equal "gid://shopify/TaxonomyCategory/aa", Category.gid("aa")
  end

  test ".parent_id_of returns the parent ID" do
    assert_nil Category.parent_id_of("aa")
    assert_equal "aa", Category.parent_id_of("aa-0")
    assert_equal "aa-0", Category.parent_id_of("aa-0-1")
  end

  test "#id must follow parent's id" do
    assert_predicate build(:category, id: "aa-0", parent:), :valid?
    assert_predicate build(:category, id: "aa-123232", parent:), :valid?
    assert_predicate build(:category, id: "bb-0", parent:), :invalid?

    child = build(:category, id: "aa-0", parent:)
    assert_predicate build(:category, id: "aa-0-1", parent: child), :valid?
    assert_predicate build(:category, id: "aa-1-1", parent: child), :invalid?
  end

  test "#id for root must be 2 chars" do
    assert_predicate build(:category, id: "t"), :invalid?
    assert_predicate build(:category, id: "ttt"), :invalid?
    assert_predicate build(:category, id: "01"), :invalid?
  end

  test "#id for roots must not have dashes" do
    assert_predicate build(:category, id: "aa-t"), :invalid?
  end

  test "#id must match depth" do
    assert_predicate build(:category, id: "aa-0", parent:), :valid?
    assert_predicate build(:category, id: "aa-0-1", parent:), :invalid?
  end

  test "#gid returns a global id" do
    assert_equal "gid://shopify/TaxonomyCategory/aa", parent.gid
    assert_equal "gid://shopify/TaxonomyCategory/aa-42", build(:category, id: "aa-42").gid
  end

  test "#root returns the top-most category node" do
    assert_equal parent, child.root
    assert_equal parent, grandchild.root
  end

  test "#ancestors walk up the tree" do
    assert_equal [child, parent], grandchild.ancestors
  end

  test "#ancestors_and_self includes self" do
    assert_equal [grandchild, child, parent], grandchild.ancestors_and_self
  end

  test "#children are sorted by name" do
    beta_child = create(:category, name: "Beta", parent:)
    alpha_child = create(:category, name: "Alpha", parent:)
    parent.reload

    assert_equal [alpha_child, beta_child], parent.children.to_a
  end

  test "#descendants is depth-first" do
    l2_beta = create(:category, name: "Beta", parent: child)
    l2_alpha = create(:category, name: "Alpha", parent: child)
    l3_child = create(:category, parent: l2_alpha)
    parent.reload

    assert_equal [child, l2_alpha, l3_child, l2_beta], parent.descendants
  end

  test "#descendants_and_self includes self" do
    grandchild.save!
    parent.reload

    assert_equal [parent, child, grandchild], parent.descendants_and_self
  end

  private

  def parent
    @parent ||= build(:category, id: "aa")
  end

  def child
    @child ||= build(:category, parent:)
  end

  def grandchild
    @grandchild ||= build(:category, parent: child)
  end
end
