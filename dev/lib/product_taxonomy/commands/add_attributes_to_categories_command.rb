# frozen_string_literal: true

module ProductTaxonomy
  class AddAttributesToCategoriesCommand < Command
    def initialize(options)
      super
      load_taxonomy
      @attribute_friendly_ids = options[:attribute_friendly_ids]
      @category_ids = options[:category_ids]
      @include_descendants = options[:include_descendants]
    end

    def execute
      add_attributes_to_categories!
      update_data_files!
    end

    private

    def add_attributes_to_categories!
      @attributes = attribute_friendly_ids.map do |friendly_id|
        attribute = Attribute.find_by(friendly_id:)
        next attribute if attribute

        raise "Attribute with friendly ID `#{friendly_id}` not found"
      end

      @categories = category_ids.map do |id|
        category = Category.find_by(id:)
        next category if category

        raise "Category with ID `#{id}` not found"
      end

      @categories = @categories.flat_map(&:descendants_and_self) if @include_descendants

      @categories.each do |category|
        @attributes.each do |attribute|
          if category.attributes.include?(attribute)
            logger.info("Category `#{category.name}` already has attribute `#{attribute.friendly_id}` - skipping")
          else
            category.add_attribute(attribute)
          end
        end
      end

      logger.info("Added #{@attributes.size} attribute(s) to #{@categories.size} categories")
    end

    def update_data_files!
      roots = @categories.map(&:root).uniq.map(&:id)
      DumpCategoriesCommand.new(verticals: roots).execute
      SyncEnLocalizationsCommand.new(targets: "categories").execute
      GenerateDocsCommand.new({}).execute
    end

    def attribute_friendly_ids
      @attribute_friendly_ids.split(",").map(&:strip)
    end

    def category_ids
      @category_ids.split(",").map(&:strip)
    end
  end
end
