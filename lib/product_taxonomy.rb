# frozen_string_literal: true

require "debug"

require_relative "product_taxonomy/version"
require_relative "product_taxonomy/cli"
require_relative "product_taxonomy/models/attribute"
require_relative "product_taxonomy/models/extended_attribute"
require_relative "product_taxonomy/models/value"
require_relative "product_taxonomy/models/category"
require_relative "product_taxonomy/models/taxonomy"

module ProductTaxonomy
  class Error < StandardError; end
  # Your code goes here...
end
