# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Dist
        class TxtSerializerTest < TestCase
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

            ProductTaxonomy::ReturnReason.add(rr1)
            ProductTaxonomy::ReturnReason.add(rr2)

            txt = TxtSerializer.serialize_all(version: "1.0", locale: "en")
            lines = txt.split("\n").reject { _1.start_with?("#") || _1.strip.empty? }

            # First non-header line should correspond to rr1 (zzz), then rr2 (aaa).
            assert_includes lines.first, "ReturnReasonDefinition/1"
            assert_includes lines.first, "Zzz"
            assert_includes lines.second, "ReturnReasonDefinition/2"
            assert_includes lines.second, "Aaa"
          end
        end
      end
    end
  end
end

