# frozen_string_literal: true

module ProductTaxonomy
  class Cli < Thor
    class_option :quiet,
      type: :boolean,
      default: false,
      aliases: ["q"],
      desc: "Suppress informational messages, only output errors"
    class_option :verbose,
      type: :boolean,
      default: false,
      aliases: ["v"],
      desc: "Enable verbose output"

    desc "dist", "Generate the taxonomy distribution"
    option :version, type: :string, desc: "The version of the taxonomy to generate"
    option :locales, type: :array, default: ["en"], desc: "The locales to generate"
    def dist
      GenerateDistCommand.new(options).run
    end

    desc "unmapped_external_categories",
      "Find categories in an external taxonomy that are not mapped from the Shopify taxonomy"
    option :external_taxonomy, type: :string, desc: "The external taxonomy to find unmapped categories in"
    def unmapped_external_categories(name_and_version)
      FindUnmappedExternalCategoriesCommand.new(options).run(name_and_version)
    end

    desc "docs", "Generate documentation files"
    option :version, type: :string, desc: "The version of the documentation to generate"
    def docs
      GenerateDocsCommand.new(options).run
    end

    desc "release", "Generate a release"
    option :version, type: :string, desc: "The version of the release to generate"
    option :locales, type: :array, default: ["en"], desc: "The locales to generate"
    def release
      GenerateReleaseCommand.new(options).run
    end

    desc "dump_categories", "Dump category verticals to YAML files"
    option :verticals, type: :array, desc: "List of vertical IDs to dump (defaults to all verticals)"
    def dump_categories
      DumpCategoriesCommand.new(options).run
    end

    desc "dump_attributes", "Dump attributes to YAML file"
    def dump_attributes
      DumpAttributesCommand.new(options).run
    end

    desc "dump_values", "Dump values to YAML file"
    def dump_values
      DumpValuesCommand.new(options).run
    end

    desc "dump_integration_full_names", "Dump `full_names.yml` from current taxonomy for integrations"
    option :version, type: :string, desc: "Version with which to label the dumped data"
    def dump_integration_full_names
      DumpIntegrationFullNamesCommand.new(options).run
    end

    desc "sync_en_localizations", "Sync English localizations for categories, attributes, and values"
    option :targets, type: :string, desc: "List of targets to sync. Valid targets are: categories, attributes, values"
    def sync_en_localizations
      SyncEnLocalizationsCommand.new(options).run
    end

    desc "add_category NAME PARENT_ID", "Add a new category to the taxonomy with NAME, as a child of PARENT_ID"
    option :id, type: :string, desc: "Override the created category's ID"
    def add_category(name, parent_id)
      AddCategoryCommand.new(options.merge(name:, parent_id:)).run
    end

    desc "add_attribute NAME DESCRIPTION", "Add a new attribute to the taxonomy with NAME and DESCRIPTION"
    option :values, type: :string, desc: "A comma separated list of values to add to the attribute"
    option :base_attribute_friendly_id, type: :string, desc: "Create an extended attribute by extending the attribute with this friendly ID"
    def add_attribute(name, description)
      AddAttributeCommand.new(options.merge(name:, description:)).run
    end

    desc "add_attributes_to_categories ATTRIBUTE_FRIENDLY_IDS CATEGORY_IDS",
      "Add one or more attributes to one or more categories. ATTRIBUTE_FRIENDLY_IDS is a comma-separated list of attribute friendly IDs."
    option :include_descendants, type: :boolean, desc: "When set, the attributes will be added to all descendants of the specified categories"
    def add_attributes_to_categories(attribute_friendly_ids, category_ids)
      AddAttributesToCategoriesCommand.new(options.merge(attribute_friendly_ids:, category_ids:)).run
    end

    desc "add_value NAME ATTRIBUTE_FRIENDLY_ID", "Add a new value with NAME to the primary attribute with ATTRIBUTE_FRIENDLY_ID"
    def add_value(name, attribute_friendly_id)
      AddValueCommand.new(options.merge(name:, attribute_friendly_id:)).run
    end
  end
end
