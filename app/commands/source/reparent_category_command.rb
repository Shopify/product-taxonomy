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
      find_category!
      find_parent!

      frame("Reparenting category") do
        logger.headline("Category: #{@category.name}")
        logger.headline("Parent: #{@parent.name}")

        update_category!
        update_data_files!
      end
    end

    private

    def find_category!
      @category = Category.find_by(id: params[:category])
      return if @category.nil?

      logger.fatal("Category `#{params[:category]}` not found")
      exit(1)
    end

    def find_parent!
      @parent = Category.find_by(id: params[:parent])
      return if @parent.nil?

      logger.fatal("Parent category `#{params[:parent]}` not found")
      exit(1)
    end

    def update_category!
      spinner("Updating category") do |sp|
        @category.reparent_to!(@parent)
        @category.reload

        sp.update_title("Updated #{@category.name} to belong to `#{@parent.name}`")
      end
    rescue Category::ReparentError => e
      logger.fatal("Failed to reparent category: #{e.message}")
      exit(1)
    end

    def update_data_files!
      DumpVerticalCommand.new(interactive: true, verticals: [@category.root.id], **params.to_h).execute
      # DumpAttributesCommand.new(interactive: true, **params.to_h).execute
      SyncEnLocalizationsCommand.new(interactive: true, **params.to_h).execute
    end
  end
end
