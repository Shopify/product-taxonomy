# frozen_string_literal: true

module ProductTaxonomy
  class AddReturnReasonsToCategoriesCommand < Command
    UNKNOWN_RETURN_REASON_FRIENDLY_ID = "unknown"
    OTHER_RETURN_REASON_FRIENDLY_ID = "other_reason"
    SPECIAL_RETURN_REASON_FRIENDLY_IDS = [
      UNKNOWN_RETURN_REASON_FRIENDLY_ID,
      OTHER_RETURN_REASON_FRIENDLY_ID,
    ].freeze

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
      special, regular = category.return_reasons.partition do |return_reason|
        SPECIAL_RETURN_REASON_FRIENDLY_IDS.include?(return_reason.friendly_id)
      end

      regular_by_friendly_id = regular.each_with_object({}) do |return_reason, by_friendly_id|
        by_friendly_id[return_reason.friendly_id] = return_reason
      end
      sorted_regular = AlphanumericSorter.sort(regular_by_friendly_id.keys).map do |friendly_id|
        regular_by_friendly_id[friendly_id]
      end

      special_by_friendly_id = special.each_with_object({}) do |return_reason, by_friendly_id|
        by_friendly_id[return_reason.friendly_id] = return_reason
      end
      sorted_special = SPECIAL_RETURN_REASON_FRIENDLY_IDS.filter_map do |friendly_id|
        special_by_friendly_id[friendly_id]
      end

      category.return_reasons.replace(sorted_regular + sorted_special)
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
