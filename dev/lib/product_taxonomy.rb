# frozen_string_literal: true

require "thor"
require "active_support/all"
require "active_model"

module ProductTaxonomy
  DATA_PATH = File.expand_path("../../data", __dir__)
end

require_relative "product_taxonomy/cli"
require_relative "product_taxonomy/alphanumeric_sorter"
require_relative "product_taxonomy/models/mixins/localized"
require_relative "product_taxonomy/models/mixins/indexed"
require_relative "product_taxonomy/models/attribute"
require_relative "product_taxonomy/models/extended_attribute"
require_relative "product_taxonomy/models/value"
require_relative "product_taxonomy/models/category"
require_relative "product_taxonomy/models/taxonomy"
require_relative "product_taxonomy/models/mapping_rule"
require_relative "product_taxonomy/models/integration_version"
require_relative "product_taxonomy/commands/command"
require_relative "product_taxonomy/commands/generate_dist_command"
require_relative "product_taxonomy/commands/find_unmapped_external_categories_command"
