# frozen_string_literal: true

module ProductTaxonomy
  class AddCategoryCommand < Command
    def initialize(options)
      super
      load_taxonomy
      @name = options[:name]
      @parent_id = options[:parent_id]
      @id = options[:id]
      # New categories inherit ancestor return reasons unless the caller opts out.
      @inherits_return_reasons = options.fetch(:inherits_return_reasons, true)
    end

    def execute
      create_category!
      update_data_files!
    end

    private

    def create_category!
      parent = Category.find_by!(id: @parent_id)
      # `:inherit` copies reasons from the closest defining ancestor at load time; an empty list defines its own.
      @new_category = Category.new(
        id: @id || parent.next_child_id,
        name: @name,
        return_reasons: @inherits_return_reasons ? :inherit : [],
        parent:,
      )
      begin
        @new_category.validate!(:create)
      rescue ActiveModel::ValidationError => e
        raise ActiveModel::ValidationError.new(e.model), "Failed to create category: #{e.message}"
      end

      parent.add_child(@new_category)
      Category.add(@new_category)
      # `load_from_source` resolves inheritance for the full tree; do it here too so the in-process dump/docs below see
      # the inherited reasons for the category we just added.
      @new_category.resolve_return_reasons
      logger.info("Created category `#{@new_category.name}` with id=`#{@new_category.id}`")
    end

    def update_data_files!
      DumpCategoriesCommand.new(verticals: [@new_category.root.id]).execute
      SyncEnLocalizationsCommand.new(targets: "categories").execute
      GenerateDocsCommand.new({}).execute
    end
  end
end
