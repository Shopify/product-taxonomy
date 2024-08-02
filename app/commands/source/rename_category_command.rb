# frozen_string_literal: true

module Source
  class RenameCategoryCommand < ApplicationCommand
    usage do
      no_command
    end

    keyword :category do
      desc "The target category ID"
      required
      validate -> { _1 =~ Category::ID_REGEX }
    end

    keyword :name do
      desc "Updated category name"
      required
    end

    def execute
      frame("Renaming existing category") do
        find_category!
        update_category!
        update_data_files!
      end
    end

    private

    def find_category!
      @category = Category.find_by(id: params[:category])
      @original_handle = @category&.handleized_name
      return if @category

      logger.fatal("Category `#{params[:category]}` not found")
      exit(1)
    end

    def update_category!
      spinner("Updating category") do |sp|
        original_name = @category.name
        @category.update!(name: params[:name])

        sp.update_title("Updated category `#{original_name}` to `#{params[:name]}`")
      end
    end

    def update_data_files!
      if @category.root?
        logger.info("Category is a vertical, deleting original data file")
        sys.delete_file!("data/categories/#{@original_handle}.yml")
      end

      DumpVerticalsCommand.new(verticals: [@category.root.id], interactive: true, **params.to_h).execute
      SyncEnLocalizationsCommand.new(interactive: true, targets: ["categories"], **params.to_h).execute
      GenerateDocsCommand.new(interactive: true, **params.to_h).execute
    end
  end
end