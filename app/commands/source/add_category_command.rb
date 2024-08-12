# frozen_string_literal: true

module Source
  class AddCategoryCommand < ApplicationCommand
    usage do
      no_command
    end

    keyword :name do
      desc "Name for the new category"
      required
    end

    keyword :parent_id do
      desc "Parent category ID for the new category"
      required
    end

    option :id do
      desc "Override the created categories ID"
      short "-i"
      long "--id string"
      validate { _1 =~ Category::ID_REGEX }
    end

    def execute
      frame("Adding new category") do
        find_parent!
        validate_id!
        create_category!
        update_data_files!
      end
    end

    private

    def find_parent!
      @parent = Category.find_by(id: params[:parent_id])
      return @parent if @parent

      logger.fatal("Parent category `#{params[:parent_id]}` not found")
      exit(1)
    end

    def validate_id!
      params[:id] ||= @parent.next_child_id
      return if params[:id].start_with?(params[:parent_id])

      logger.fatal("ID `#{params[:id]}` does not start with parent ID `#{params[:parent_id]}`")
      exit(1)
    end

    def create_category!
      spinner("Creating category") do |sp|
        @new_category = Category
          .create_with(id: params[:id])
          .find_or_create_by(
            name: params[:name],
            parent_id: params[:parent_id],
          )

        if @new_category.valid?
          sp.update_title("Created category `#{@new_category.name}` with id=`#{@new_category.id}`")
        else
          logger.fatal("Failed to create category: #{new_category.errors.full_messages.to_sentence}")
          exit(1)
        end
      end
    end

    def update_data_files!
      DumpVerticalsCommand.new(verticals: [@new_category.root.id], interactive: true, **params.to_h).execute
      SyncEnLocalizationsCommand.new(interactive: true, targets: ["categories"], **params.to_h).execute
      GenerateDocsCommand.new(interactive: true, **params.to_h).execute
    end
  end
end
