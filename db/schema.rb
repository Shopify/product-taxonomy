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

    t.index(:friendly_id, unique: true)
  end
  create_table :property_values, force: :cascade do |t|
    t.string(:name, null: false)
  end

  create_table :categories_properties, id: false, force: :cascade do |t|
    t.string(:category_id, null: false)
    t.string(:property_friendly_id, null: false)

    t.index([:category_id, :property_friendly_id], unique: true)
    t.index(:property_friendly_id)
  end
  create_table :properties_property_values, id: false, force: :cascade do |t|
    t.integer(:property_id, null: false)
    t.integer(:property_value_id, null: false)

    t.index([:property_id, :property_value_id], unique: true)
    t.index(:property_value_id)
  end
end
