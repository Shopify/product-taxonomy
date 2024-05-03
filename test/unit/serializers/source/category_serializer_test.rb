# frozen_string_literal: true

require_relative "../../../test_helper"

module Serializers
  module Source
    class CategorySerializerTest < ActiveSupport::TestCase
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
        category = Category.new(id: "aa-123", name: "foo")

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
        categories = [
          Category.new(id: "aa-123", name: "foo"),
          Category.new(id: "bb", name: "bar"),
        ]

        assert_equal(
          [
            {
              "id" => "aa-123",
              "name" => "foo",
              "children" => [],
              "attributes" => [],
            },
            {
              "id" => "bb",
              "name" => "bar",
              "children" => [],
              "attributes" => [],
            },
          ],
          ::Source::CategorySerializer.pack_all(categories),
        )
      end
    end
  end
end
