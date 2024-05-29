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

  test ".as_txt returns version string representation" do
    assert_equal <<~TXT.strip, MappingRule.as_txt([mapping_rule], version: 1)
      # Shopify Product Taxonomy - Mapping shopify/v1 to google/v1
      # Format:
      # → {base taxonomy category name}
      # ⇒ {mapped taxonomy category name}

      → Apparel & Accessories
      ⇒ Apparel & Accessories
    TXT
  end

  test ".as_txt generates a version string and omits entries where the input and output categories originate from the same taxonomy and have identical names" do
    mapping_same = build(
      :mapping_rule,
      integration_id: integration_shopify.id,
      input: build(
        :product,
        payload: { "properties" => nil, "product_category_id" => "gid://shopify/TaxonomyCategory/1" },
        full_name: "Apparel & Accessories",
      ),
      output: shopify_product,
      input_version: "shopify/v0",
      output_version: "shopify/v1",
    )
    mapping_short = build(
      :mapping_rule,
      integration_id: integration_shopify.id,
      input: build(
        :product,
        payload: { "properties" => nil, "product_category_id" => "gid://shopify/TaxonomyCategory/100001" },
        full_name: "Media > DVDs & Videos",
      ),
      output: build(
        :product,
        payload: { "properties" => nil, "product_category_id" => "gid://shopify/TaxonomyCategory/me" },
        full_name: "Media > Videos",
      ),
      input_version: "shopify/v0",
      output_version: "shopify/v1",
    )
    mapping_long = build(
      :mapping_rule,
      integration_id: integration_shopify.id,
      input: build(
        :product,
        payload: { "properties" => nil, "product_category_id" => "gid://shopify/TaxonomyCategory/200002" },
        full_name: "Electronics > Communications > Telephony > Mobile Phone Accessories > Mobile Phone Cases",
      ),
      output: build(
        :product,
        payload: { "properties" => nil, "product_category_id" => "gid://shopify/TaxonomyCategory/el-4-8-4" },
        full_name: "Electronics > Communications > Telephony > Mobile & Smart Phone Accessories > Mobile Phone Cases",
      ),
      input_version: "shopify/v0",
      output_version: "shopify/v1",
    )

    assert_equal <<~TXT.strip, MappingRule.as_txt([mapping_same, mapping_short, mapping_long], version: 1)
      # Shopify Product Taxonomy - Mapping shopify/v0 to shopify/v1
      # Format:
      # → {base taxonomy category name}
      # ⇒ {mapped taxonomy category name}

      → Electronics > Communications > Telephony > Mobile Phone Accessories > Mobile Phone Cases
      ⇒ Electronics > Communications > Telephony > Mobile & Smart Phone Accessories > Mobile Phone Cases

      → Media > DVDs & Videos
      ⇒ Media > Videos
    TXT
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
      payload: { "properties" => nil, "product_category_id" => "gid://shopify/TaxonomyCategory/aa" },
      full_name: "Apparel & Accessories",
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
      payload: { "properties" => nil, "product_category_id" => ["1"] },
      full_name: "Apparel & Accessories",
    )
  end

  def attribute
    @attribute ||= build(:attribute,)
  end

  def value
    @value ||= build(:value,)
  end
end
