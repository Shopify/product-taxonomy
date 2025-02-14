# frozen_string_literal: true

require "thor"
require "active_support/all"
require "active_model"

module ProductTaxonomy
  DATA_PATH = File.expand_path("../../data", __dir__)
  private_constant :DATA_PATH

  class << self
    def data_path = DATA_PATH
  end
end

require_relative "product_taxonomy/cli"
require_relative "product_taxonomy/alphanumeric_sorter"
require_relative "product_taxonomy/identifier_formatter"
require_relative "product_taxonomy/localizations_validator"
require_relative "product_taxonomy/models/mixins/localized"
require_relative "product_taxonomy/models/mixins/indexed"
require_relative "product_taxonomy/models/attribute"
require_relative "product_taxonomy/models/extended_attribute"
require_relative "product_taxonomy/models/value"
require_relative "product_taxonomy/models/category"
require_relative "product_taxonomy/models/taxonomy"
require_relative "product_taxonomy/models/mapping_rule"
require_relative "product_taxonomy/models/integration_version"
require_relative "product_taxonomy/models/serializers/category/data/data_serializer"
require_relative "product_taxonomy/models/serializers/category/data/localizations_serializer"
require_relative "product_taxonomy/models/serializers/category/docs/siblings_serializer"
require_relative "product_taxonomy/models/serializers/category/docs/search_serializer"
require_relative "product_taxonomy/models/serializers/attribute/data/localizations_serializer"
require_relative "product_taxonomy/models/serializers/attribute/docs/base_and_extended_serializer"
require_relative "product_taxonomy/models/serializers/attribute/docs/reversed_serializer"
require_relative "product_taxonomy/models/serializers/attribute/docs/search_serializer"
require_relative "product_taxonomy/models/serializers/value/data/localizations_serializer"
require_relative "product_taxonomy/commands/command"
require_relative "product_taxonomy/commands/generate_dist_command"
require_relative "product_taxonomy/commands/find_unmapped_external_categories_command"
require_relative "product_taxonomy/commands/generate_docs_command"
require_relative "product_taxonomy/commands/generate_release_command"
require_relative "product_taxonomy/commands/dump_categories_command"
require_relative "product_taxonomy/commands/sync_en_localizations_command"
