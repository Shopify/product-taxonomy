# frozen_string_literal: true

require_relative "../../../test_helper"

module Serializers
  module Source
    class CategoriesPropertySerializerTest < ActiveSupport::TestCase
      test "#unpack is an array of joins" do
        data = {
          "id" => 1,
          "attributes" => ["foo", "bar"],
        }

        assert_equal(
          [
            { "category_id" => 1, "property_friendly_id" => "foo" },
            { "category_id" => 1, "property_friendly_id" => "bar" },
          ],
          ::Source::CategoriesPropertySerializer.unpack(data),
        )
      end

      test "#unpack_all is a flat array of joins" do
        data_list = [
          {
            "id" => 1,
            "attributes" => ["foo", "bar"],
          },
          {
            "id" => 2,
            "attributes" => ["baz", "qux"],
          },
        ]

        assert_equal(
          [
            { "category_id" => 1, "property_friendly_id" => "foo" },
            { "category_id" => 1, "property_friendly_id" => "bar" },
            { "category_id" => 2, "property_friendly_id" => "baz" },
            { "category_id" => 2, "property_friendly_id" => "qux" },
          ],
          ::Source::CategoriesPropertySerializer.unpack_all(data_list),
        )
      end
    end
  end
end
