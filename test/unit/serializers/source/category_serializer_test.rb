# frozen_string_literal: true

require_relative "../../../test_helper"

module Serializers
  module Source
    class CategorySerializerTest < ApplicationTestCase
      def teardown
        Category.delete_all
        Property.delete_all
      end

      test "#unpack is well formed" do
        data = {
          "id" => "aa-123",
          "name" => "foo",
        }

        assert_equal(
          {
            "id" => "aa-123",
            "parent_id" => "aa",
            "name" => "foo",
          },
          ::Source::CategorySerializer.unpack(data),
        )
      end

      test "#unpack_all is a flat array of categories" do
        data_list = [
          {
            "id" => "aa-123",
            "name" => "foo",
          },
          {
            "id" => "bb",
            "name" => "bar",
          },
        ]

        assert_equal(
          [
            {
              "id" => "aa-123",
              "parent_id" => "aa",
              "name" => "foo",
            },
            {
              "id" => "bb",
              "parent_id" => nil,
              "name" => "bar",
            },
          ],
          ::Source::CategorySerializer.unpack_all(data_list),
        )
      end

      test "#pack is well formed for simple Category" do
        category = build(:category, id: "aa-123", name: "foo")

        assert_equal(
          {
            "id" => "aa-123",
            "name" => "foo",
            "children" => [],
            "attributes" => [],
          },
          ::Source::CategorySerializer.pack(category),
        )
      end

      test "#pack_all is well formed for multiple Categories" do
        Category.delete_all

        color = build(:property, name: "Color")
        size = build(:property, name: "Size")
        parent = build(:category, id: "aa", properties: [color])
        child = create(:category, id: "aa-123", parent:, properties: [color, size])

        parent.reload
        categories = [parent, child]

        assert_equal(
          [
            {
              "id" => "aa",
              "name" => "Category aa",
              "children" => ["aa-123"],
              "attributes" => ["color"],
            },
            {
              "id" => "aa-123",
              "name" => "Category aa-123",
              "children" => [],
              "attributes" => ["color", "size"],
            },
          ],
          ::Source::CategorySerializer.pack_all(categories),
        )
      end
    end
  end
end
