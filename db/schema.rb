# frozen_string_literal: true

ActiveRecord::Schema[7.1].define do
  create_table :categories, id: :string, force: :cascade do |t|
    t.string(:name, null: false)
    t.string(:parent_id)

    t.index(:parent_id)
  end
  create_table :properties, force: :cascade do |t|
    t.string(:name, null: false)
    t.string(:friendly_id, null: false)
    t.string(:handle, null: false)

    t.index(:friendly_id, unique: true)
  end
  create_table :property_values, force: :cascade do |t|
    t.string(:name, null: false)
    t.string(:friendly_id, null: false)
    t.string(:handle, null: false)
    t.string(:primary_property_friendly_id) # nullable to avoid cyclic dependency

    t.index(:friendly_id, unique: true)
    t.index(:primary_property_friendly_id)
  end

  create_table :categories_properties, id: false, force: :cascade do |t|
    t.string(:category_id, null: false)
    t.string(:property_friendly_id, null: false)

    t.index([:category_id, :property_friendly_id], unique: true)
    t.index(:property_friendly_id)
  end
  create_table :properties_property_values, id: false, force: :cascade do |t|
    t.integer(:property_id, null: false)
    t.string(:property_value_friendly_id, null: false)

    t.index([:property_id, :property_value_friendly_id], unique: true)
    t.index(:property_value_friendly_id)
  end

  create_table :integrations, force: :cascade do |t|
    t.string(:name, null: false)
    t.text(:available_versions)
    t.index(:name, unique: true)
  end

  create_table :products, force: :cascade do |t|
    t.text(:payload)
    t.string(:type)
    t.index([:type, :payload], unique: true)
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
