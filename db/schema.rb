# frozen_string_literal: true

ActiveRecord::Schema[7.1].define do
  create_table :categories, id: :string, force: :cascade do |t|
    t.string(:name, null: false)
    t.string(:parent_id)

    t.index(:parent_id)
  end
  create_table :attributes, force: :cascade do |t|
    t.string(:name, null: false)
    t.string(:friendly_id, null: false)
    t.string(:base_friendly_id)
    t.string(:handle, null: false)
    t.string(:description, null: false)

    t.index(:friendly_id, unique: true)
  end
  create_table :values, force: :cascade do |t|
    t.string(:name, null: false)
    t.string(:friendly_id, null: false)
    t.string(:handle, null: false)
    t.string(:primary_attribute_friendly_id) # nullable to avoid cyclic dependency

    t.index(:friendly_id, unique: true)
    t.index(:primary_attribute_friendly_id)
  end

  create_table :categories_attributes, id: false, force: :cascade do |t|
    t.string(:category_id, null: false)
    t.string(:attribute_friendly_id, null: false)

    t.index([:category_id, :attribute_friendly_id], unique: true)
    t.index(:attribute_friendly_id)
  end
  create_table :attributes_values, id: false, force: :cascade do |t|
    t.integer(:attribute_id, null: false)
    t.string(:value_friendly_id, null: false)

    t.index([:attribute_id, :value_friendly_id], unique: true)
    t.index(:value_friendly_id)
  end

  create_table :integrations, force: :cascade do |t|
    t.string(:name, null: false)
    t.text(:available_versions)
    t.index(:name, unique: true)
  end

  create_table :products, force: :cascade do |t|
    t.text(:payload)
    t.string(:type)
    t.string(:full_name)
    t.index([:type, :payload, :full_name], unique: true)
  end

  create_table :mapping_rules, force: :cascade do |t|
    t.integer(:integration_id, null: false)
    t.boolean(:from_shopify, default: true)
    t.integer(:input_id, null: false)
    t.integer(:output_id, null: false)
    t.string(:input_type, null: false)
    t.string(:output_type, null: false)
    t.string(:input_version, null: false)
    t.string(:output_version, null: false)

    t.index([:integration_id], name: "index_mapping_rules_on_integration_id")
    t.index([:input_id, :output_id], name: "index_unique_mapping_rule", unique: true)
  end
end
