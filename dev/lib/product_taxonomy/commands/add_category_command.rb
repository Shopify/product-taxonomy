# frozen_string_literal: true

module ProductTaxonomy
  class AddCategoryCommand < Command
    def initialize(options)
      super
      load_taxonomy
      @name = options[:name]
      @parent_id = options[:parent_id]
      @id = options[:id]
    end

    def execute
      create_category!
      update_data_files!
    end

    private

    def create_category!
      parent = Category.find_by!(id: @parent_id)
      @new_category = Category.new(id: @id || parent.next_child_id, name: @name, parent:)
      raise "Failed to create category: #{@new_category.errors.full_messages.to_sentence}" unless @new_category.valid?

      parent.add_child(@new_category)
      Category.add(@new_category)
      logger.info("Created category `#{@new_category.name}` with id=`#{@new_category.id}`")
    end

    def update_data_files!
      DumpCategoriesCommand.new(verticals: [@new_category.root.id]).execute
      SyncEnLocalizationsCommand.new(targets: "categories").execute
      GenerateDocsCommand.new({}).execute
    end
  end
end
