# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "product_taxonomy"
require "active_support/testing/autorun"
require "minitest/benchmark"
require "minitest/pride"
require "minitest/hooks/default"
require "mocha/minitest"

module ProductTaxonomy
  class TestCase < ActiveSupport::TestCase
    teardown do
      ProductTaxonomy::Value.reset
      ProductTaxonomy::Attribute.reset
      ProductTaxonomy::Category.reset
    end
  end
end
