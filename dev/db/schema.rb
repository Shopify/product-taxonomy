require 'active_record'
require 'sqlite3'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Schema.define do
  create_table :categories, id: :string do |t|
    t.string :name, null: false
    t.string :parent_id

    t.index :parent_id
  end
  create_table :properties do |t|
    t.string :name, null: false
  end
  create_table :property_values, id: :string do |t|
    t.string :name, null: false
  end

  create_table :categories_properties, id: false do |t|
    t.string :category_id, null: false
    t.integer :property_id, null: false

    t.index [:category_id, :property_id], unique: true
    t.index :property_id
  end
  create_table :properties_property_values, id: false do |t|
    t.integer :property_id, null: false
    t.string :property_value_id, null: false

    t.index [:property_id, :property_value_id], unique: true
    t.index :property_value_id
  end
end
