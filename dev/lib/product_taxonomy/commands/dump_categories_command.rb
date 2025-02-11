# frozen_string_literal: true

module ProductTaxonomy
  class DumpCategoriesCommand < Command
    def initialize(options)
      super
      load_taxonomy
      @verticals = options[:verticals] || Category.verticals.map(&:id)
    end

    def execute
      logger.info("Dumping #{@verticals.size} verticals")

      @verticals.each do |vertical_id|
        vertical_root = Category.find_by(id: vertical_id)
        raise "Vertical not found: #{vertical_id}" unless vertical_root
        raise "Category #{vertical_id} is not a vertical" unless vertical_root.root?

        logger.info("Updating `#{vertical_root.name}`...")
        path = File.expand_path("categories/#{vertical_root.friendly_name}.yml", ProductTaxonomy.data_path)
        data = Serializers::Category::Data::DataSerializer.serialize_all(vertical_root)
        File.write(path, YAML.dump(data, line_width: -1))
        logger.info("Updated `#{path}`")
      end
    end
  end
end
