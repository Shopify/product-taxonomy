# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Dist
        class JsonSerializerTest < TestCase
          test "serialize_all preserves return reasons source order" do
            rr1 = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Zzz",
              description: "Zzz",
              friendly_id: "zzz",
              handle: "zzz",
            )
            rr2 = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Aaa",
              description: "Aaa",
              friendly_id: "aaa",
              handle: "aaa",
            )

            # Add out-of-alphabetical order to ensure we don't sort by name.
            ProductTaxonomy::ReturnReason.add(rr1)
            ProductTaxonomy::ReturnReason.add(rr2)

            json = JsonSerializer.serialize_all(version: "1.0", locale: "en")
            handles = json.fetch("return_reasons").map { _1.fetch("handle") }

            assert_equal ["zzz", "aaa"], handles
          end
        end
      end
    end
  end
end

