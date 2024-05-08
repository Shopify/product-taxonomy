# frozen_string_literal: true

require_relative "../test_helper"

class CategoryTest < ApplicationTestCase
  def teardown
    Category.delete_all
    Property.delete_all
  end

  test ".gid returns a global id" do
    assert_equal "gid://shopify/TaxonomyCategory/aa", Category.gid("aa")
  end

  test "#id must follow parent's id" do
    assert_predicate build(:category, id: "aa-0", parent:), :valid?
    assert_predicate build(:category, id: "aa-123232", parent:), :valid?
    assert_predicate build(:category, id: "bb-0", parent:), :invalid?

    child = build(:category, id: "aa-0", parent:)
    assert_predicate build(:category, id: "aa-0-1", parent: child), :valid?
    assert_predicate build(:category, id: "aa-1-1", parent: child), :invalid?
  end

  test "#id for root must be only 2 chars" do
    assert_predicate build(:category, id: "tt"), :valid?

    assert_predicate build(:category, id: "t"), :invalid?
    assert_predicate build(:category, id: "ttt"), :invalid?
    assert_predicate build(:category, id: "01"), :invalid?
  end

  test "#id must match depth" do
    assert_predicate build(:category, id: "aa-t"), :invalid?
    assert_predicate build(:category, id: "aa-0-1", parent:), :invalid?

    assert_predicate build(:category, id: "aa-0", parent:), :valid?
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

  test ".new_from_data creates a new category" do
    category = Category.new_from_data("id" => "aa", "name" => "Alpha")

    assert_equal "aa", category.id
    assert_equal "Alpha", category.name
    assert_nil category.parent_id

    child_category = Category.new_from_data("id" => "aa-0", "name" => "Beta")

    assert_equal "aa-0", child_category.id
    assert_equal "Beta", child_category.name
    assert_equal "aa", child_category.parent_id
  end

  test ".insert_all_from_data creates multiple categories" do
    data = [
      { "id" => "aa", "name" => "Alpha" },
      { "id" => "aa-0", "name" => "Beta" },
    ]

    assert_difference -> { Category.count }, 2 do
      Category.insert_all_from_data(data)
    end
  end

  test ".as_json returns distribution json" do
    child.save!
    parent.reload

    assert_equal(
      {
        "version" => 1,
        "verticals" => [
          {
            "name" => "Category aa",
            "prefix" => "aa",
            "categories" => [
              {
                "id" => "gid://shopify/TaxonomyCategory/aa",
                "level" => 0,
                "name" => "Category aa",
                "full_name" => "Category aa",
                "parent_id" => nil,
                "attributes" => [],
                "children" => [
                  {
                    "id" => "gid://shopify/TaxonomyCategory/aa-1",
                    "name" => "Category aa-1",
                  },
                ],
                "ancestors" => [],
              },
              {
                "id" => "gid://shopify/TaxonomyCategory/aa-1",
                "level" => 1,
                "name" => "Category aa-1",
                "full_name" => "Category aa > Category aa-1",
                "parent_id" => "gid://shopify/TaxonomyCategory/aa",
                "attributes" => [],
                "children" => [],
                "ancestors" => [
                  {
                    "id" => "gid://shopify/TaxonomyCategory/aa",
                    "name" => "Category aa",
                  },
                ],
              },
            ],
          },
        ],
      },
      Category.as_json([parent], version: 1),
    )
  end

  test ".as_txt returns padded and version string representation" do
    child.save!
    parent.reload

    assert_equal <<~TXT.strip, Category.as_txt([parent], version: 1)
      # Shopify Product Taxonomy - Categories: 1
      # Format: {GID} : {Ancestor name} > ... > {Category name}

      gid://shopify/TaxonomyCategory/aa   : Category aa
      gid://shopify/TaxonomyCategory/aa-1 : Category aa > Category aa-1
    TXT
  end

  test "#as_json_for_data returns data json" do
    child.save!
    color = create(:property, name: "Color")
    parent.properties = [color]
    parent.save!

    parent.reload

    assert_equal(
      {
        "id" => "aa",
        "name" => "Category aa",
        "children" => ["aa-1"],
        "attributes" => [color.friendly_id],
      },
      parent.as_json_for_data,
    )
  end

  private

  def parent
    @parent ||= build(:category, id: "aa")
  end

  def child
    @child ||= build(:category, id: "aa-1", parent:)
  end

  def grandchild
    @grandchild ||= build(:category, id: "aa-1-1", parent: child)
  end
end
