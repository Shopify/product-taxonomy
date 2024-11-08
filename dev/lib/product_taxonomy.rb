# typed: strict
# frozen_string_literal: true

require "thor"
require "active_support/all"
require "sorbet-runtime"

require_relative "product_taxonomy/cli"
require_relative "product_taxonomy/models/attribute"
require_relative "product_taxonomy/models/extended_attribute"
require_relative "product_taxonomy/models/value"
require_relative "product_taxonomy/models/category"
require_relative "product_taxonomy/models/taxonomy"
