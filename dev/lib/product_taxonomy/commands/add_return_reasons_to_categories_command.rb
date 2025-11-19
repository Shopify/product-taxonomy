# frozen_string_literal: true

module ProductTaxonomy
  class AddReturnReasonsToCategoriesCommand < Command
    def initialize(options)
      super
      load_taxonomy
      @return_reason_friendly_ids = options[:return_reason_friendly_ids]
      @category_ids = options[:category_ids]
      @include_descendants = options[:include_descendants]
    end

    def execute
      add_return_reasons_to_categories!
      update_data_files!
    end

    private

    def add_return_reasons_to_categories!
      @return_reasons = return_reason_friendly_ids.map { |friendly_id| ReturnReason.find_by!(friendly_id:) }
      @categories = category_ids.map { |id| Category.find_by!(id:) }
      @categories = @categories.flat_map(&:descendants_and_self) if @include_descendants

      @categories.each do |category|
        @return_reasons.each do |return_reason|
          if category.return_reasons.include?(return_reason)
            logger.info("Category `#{category.name}` already has return reason `#{return_reason.friendly_id}` - skipping")
          else
            category.add_return_reason(return_reason)
          end
        end

        sort_return_reasons!(category)
      end

      logger.info("Added #{@return_reasons.size} return reason(s) to #{@categories.size} categories")
    end

    def sort_return_reasons!(category)
      special_reasons = category.return_reasons.select { |r| ["unknown", "other"].include?(r.friendly_id) }
      regular_reasons = category.return_reasons.reject { |r| ["unknown", "other"].include?(r.friendly_id) }

      sorted_friendly_ids = AlphanumericSorter.sort(regular_reasons.map(&:friendly_id))
      regular_reasons = sorted_friendly_ids.map { |fid| regular_reasons.find { |r| r.friendly_id == fid } }

      # Add special reasons at the end in the correct order
      unknown = special_reasons.find { |r| r.friendly_id == "unknown" }
      other = special_reasons.find { |r| r.friendly_id == "other" }

      sorted_reasons = regular_reasons + [unknown, other].compact

      category.return_reasons.replace(sorted_reasons)
    end

    def update_data_files!
      roots = @categories.map(&:root).uniq.map(&:id)
      DumpCategoriesCommand.new(verticals: roots).execute
      SyncEnLocalizationsCommand.new(targets: "categories").execute
      GenerateDocsCommand.new({}).execute
    end

    def return_reason_friendly_ids
      @return_reason_friendly_ids.split(",").map(&:strip)
    end

    def category_ids
      @category_ids.split(",").map(&:strip)
    end
  end
end
