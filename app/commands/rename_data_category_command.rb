# frozen_string_literal: true

class RenameDataCategoryCommand < ApplicationCommand
  usage do
    no_command
  end

  keyword :id do
    desc "The target category ID"
    required
    validate { _1 =~ Category::ID_REGEX }
  end

  keyword :name do
    desc "Updated category name"
    required
  end

  def execute
    frame("Renaming existing category") do
      find_category!
      update_category!
      update_vertical_file!
      sync_localizations!
    end
  end

  private

  def find_category!
    @category = Category.find_by(id: params[:id])
    @original_handle = @category&.handleized_name
    return if @category

    logger.fatal("Category `#{params[:id]}` not found")
    exit(1)
  end

  def update_category!
    spinner("Updating category") do |sp|
      original_name = @category.name
      @category.update!(name: params[:name])

      sp.update_title("Updated category `#{original_name}` to `#{params[:name]}`")
    end
  end

  def update_vertical_file!
    if @category.root?
      logger.info("Category is a vertical, renaming data file")
      sys.move_file!("data/categories/#{@original_handle}.yml", "data/categories/#{@category.handleized_name}.yml")
    end

    spinner("Updating vertical file") do |sp|
      vertical = @category.root
      sys.write_file!("data/categories/#{vertical.handleized_name}.yml") do |file|
        file.write(vertical.as_json_for_data_with_descendants.to_yaml)
      end
      sp.update_title("Updated vertical `#{vertical.name}`")
    end
  end

  def sync_localizations!
    spinner("Syncing localizations") do |sp|
      SyncEnLocalizationsCommand.new(**params.to_h).execute
      sp.update_title("Synced localizations")
    end
  end
end
