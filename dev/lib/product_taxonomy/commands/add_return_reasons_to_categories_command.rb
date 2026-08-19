# frozen_string_literal: true

module ProductTaxonomy
  class AddReturnReasonsToCategoriesCommand < Command
    UNKNOWN_RETURN_REASON_FRIENDLY_ID = "unknown"
    OTHER_RETURN_REASON_FRIENDLY_ID = "other_reason"
    # Global reasons are always ordered at the end of a category's list, in this exact order.
    GLOBAL_RETURN_REASON_FRIENDLY_IDS = [
      "changed_my_mind",
      "item_not_as_described",
      "received_the_wrong_item",
      "damaged_or_defective",
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
        # A category with no reasons of its own yet — empty, or inheriting from an ancestor — is defined from
        # scratch, so it also gets the global reasons appended (ordered at the end by sort_return_reasons!).
        from_scratch = category.inherits_return_reasons || category.return_reasons.empty?

        if category.inherits_return_reasons
          logger.info("Category `#{category.name}` inherited its return reasons - replacing them with the new return reason(s) and the global return reasons")
        end

        @return_reasons.each do |return_reason|
          # An inheriting category's reasons come from its parent; adding materializes them, so don't treat
          # inherited reasons as "already present" and skip.
          if !category.inherits_return_reasons && category.return_reasons.include?(return_reason)
            logger.info("Category `#{category.name}` already has return reason `#{return_reason.friendly_id}` - skipping")
          else
            category.add_return_reason(return_reason)
          end
        end

        append_global_return_reasons!(category) if from_scratch

        sort_return_reasons!(category)
      end

      logger.info("Added #{@return_reasons.size} return reason(s) to #{@categories.size} categories")
    end

    def append_global_return_reasons!(category)
      global_return_reasons.each do |return_reason|
        next if category.return_reasons.include?(return_reason)

        category.add_return_reason(return_reason)
      end
    end

    def global_return_reasons
      @global_return_reasons ||= GLOBAL_RETURN_REASON_FRIENDLY_IDS.map { |friendly_id| ReturnReason.find_by!(friendly_id:) }
    end

    # Move the global reasons to the end in their defined order, preserving the order of all other reasons.
    def sort_return_reasons!(category)
      global, regular = category.return_reasons.partition do |return_reason|
        GLOBAL_RETURN_REASON_FRIENDLY_IDS.include?(return_reason.friendly_id)
      end

      sorted_global = GLOBAL_RETURN_REASON_FRIENDLY_IDS.filter_map do |friendly_id|
        global.find { |return_reason| return_reason.friendly_id == friendly_id }
      end

      category.return_reasons.replace(regular + sorted_global)
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
