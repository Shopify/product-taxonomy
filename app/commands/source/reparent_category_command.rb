# frozen_string_literal: true

module Source
  class ReparentCategoryCommand < ApplicationCommand
    usage do
      no_command
    end

    keyword :category do
      desc "The target category ID"
      required
      validate { _1 =~ Category::ID_REGEX }
    end

    keyword :parent do
      desc "The new parent category ID"
      required
      validate { _1 =~ Category::ID_REGEX }
    end

    def execute
      find_and_verify_category!
      find_and_verify_parent!

      frame("Reparenting category") do
        logger.headline("Category: #{@category.name}")
        logger.headline("Parent: #{@parent.name}")

        update_category!
        update_vertical_file!
        sync_localizations!
      end
    end

    private

    def find_and_verify_category!
      @category = Category.find_by(id: params[:category])

      if @category.nil?
        logger.fatal("Category `#{params[:category]}` not found")
        exit(1)
      elsif @category.root?
        logger.fatal("Cannot reparent a vertical")
        exit(1)
      end
    end

    def find_and_verify_parent!
      @parent = Category.find_by(id: params[:parent])

      if @parent.nil?
        logger.fatal("Parent category `#{params[:parent]}` not found")
        exit(1)
      elsif @category.descendants.include?(@parent)
        logger.fatal("Cannot reparent to a descendant category")
        exit(1)
      end
    end

    def update_category!
      spinner("Updating category") do |sp|
        Category.transaction do
          original_id = @category.id
          new_id = @parent.next_child_id
          @category.update_columns(id: new_id, parent_id: @parent.id)
          # TODO: need to refresh all children IDs iteratively so the ID structure is respected
          Category.where(parent_id: original_id).update_all(parent_id: new_id)
        end
        @category.reload

        sp.update_title("Updated #{@category.name} to belong to `#{@parent.name}`")
      end
    end

    def update_vertical_file!
      DumpVerticalCommand.new(verticals: [@category.root.id], interactive: true, **params.to_h).execute
    end

    def sync_localizations!
      SyncEnLocalizationsCommand.new(interactive: true, **params.to_h).execute
    end
  end
end
