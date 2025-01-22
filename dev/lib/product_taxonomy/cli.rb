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
  end
end
