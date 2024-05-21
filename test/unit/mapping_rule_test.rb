# frozen_string_literal: true

require_relative "../test_helper"

class MappingRuleTest < ActiveSupport::TestCase
  def teardown
    Product.delete_all
    GoogleProduct.delete_all
    MappingRule.delete_all
    Integration.delete_all
    Attribute.delete_all
    Value.delete_all
  end

  test ".as_json returns distribution json" do
    integration_shopify.save!
    mapping_rule.save!

    assert_equal(
      {
        "version" => 1,
        "mappings"=>[
          {
            "input_taxonomy"=>"shopify/v1",
            "output_taxonomy"=>"google/v1",
            "rules" => [
              {
                "input" => {
                  "product_category_id" => "gid://shopify/TaxonomyCategory/aa"
                },
                "output" => {
                  "product_category_id" => ["1"]
                }
              }
            ]
          }
        ],
      },
      MappingRule.as_json([mapping_rule], version: 1),
    )
  end

  test "#as_json returns data json" do
    assert_equal(
      {
        "input" => {
          "product_category_id" => "gid://shopify/TaxonomyCategory/aa"
        },
        "output" => {
          "product_category_id" => ["1"]
        }
      },
      mapping_rule.as_json,
    )
  end

  test "#as_json returns resolved attributes when present" do
    attribute.save!
    value.save!

    assert_equal(
      {
        "input" => {
          "product_category_id" => "gid://shopify/TaxonomyCategory/aa",
          "attributes" => [{ "attribute" => attribute.gid, "value" => value.gid }]
        },
        "output" => {
          "product_category_id" => ["1"]
        }
      },
      mapping_rule_with_attributes.as_json.sort.to_h,
    )
  end

  private

  def integration_shopify
    @integration_shopify ||= build(:integration, name: "shopify", available_versions: ["shopify/v1"])
  end

  def mapping_rule
    @mapping_rule ||= build(
      :mapping_rule,
      integration_id: integration_shopify.id,
      input: shopify_product,
      output: google_product,
      input_version: "shopify/v1",
      output_version: "google/v1",
    )
  end

  def mapping_rule_with_attributes
    @mapping_rule_with_attributes ||= build(
      :mapping_rule,
      integration_id: integration_shopify.id,
      input: shopify_product_with_attributes,
      output: google_product,
      input_version: "shopify/v1",
      output_version: "google/v1",
    )
  end

  def shopify_product
    @shopify_product ||= build(
      :product,
      payload: { "properties" => nil , "product_category_id" => "gid://shopify/TaxonomyCategory/aa" },
    )
  end

  def shopify_product_with_attributes
    @shopify_product_with_attributes ||= build(
      :product,
      payload: {
        "properties" => [{ "attribute" => attribute.friendly_id, "value" => value.friendly_id }] ,
        "product_category_id" => "gid://shopify/TaxonomyCategory/aa",
      },
    )
  end

  def google_product
    @google_product ||= build(
      :google_product,
      payload: { "properties" => nil , "product_category_id" => ["1"] },
    )
  end

  def attribute
    @attribute ||= build(:attribute,)
  end

  def value
    @value ||= build(:value,)
  end
end
