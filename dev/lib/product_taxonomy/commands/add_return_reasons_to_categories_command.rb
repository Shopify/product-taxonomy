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
            category.return_reasons << return_reason
          end
        end
        
        sort_return_reasons!(category)
      end

      logger.info("Added #{@return_reasons.size} return reason(s) to #{@categories.size} categories")
    end
    
    def sort_return_reasons!(category)
      special_reasons = category.return_reasons.select { |r| ['unknown', 'other'].include?(r.friendly_id) }
      regular_reasons = category.return_reasons.reject { |r| ['unknown', 'other'].include?(r.friendly_id) }
      
      regular_reasons.sort_by!(&:name)
      
      sorted_reasons = regular_reasons.dup
      sorted_reasons << special_reasons.find { |r| r.friendly_id == 'unknown' } if special_reasons.any? { |r| r.friendly_id == 'unknown' }
      sorted_reasons << special_reasons.find { |r| r.friendly_id == 'other' } if special_reasons.any? { |r| r.friendly_id == 'other' }
      
      category.instance_variable_set(:@return_reasons, sorted_reasons)
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



