# frozen_string_literal: true

module Source
  class AddAttributeToCategoriesCommand < ApplicationCommand
    usage do
      no_command
    end

    keyword :attribute_id do
      desc "Attribute ID for the attribute to be added"
      required
    end

    keyword :category_ids do
      desc "A comma separated list of category ID(s) the attribute will be added to"
      required
    end

    option :include_descendants do
      desc "When set, the attribute will be added to all descendants of the specified categories"
      short "-d"
      long "--descendants"
    end

    def execute
      setup!
      frame("Adding Attribute") do
        add_to_attribute!
        update_data_files!
      end
    end

    private

    def setup!
      load_attribute
      load_categories
    end

    def load_attribute
      @attribute = Attribute.find_by(id: params[:attribute_id])
      return @attribute if @attribute

      logger.fatal("Attribute`#{params[:attribute_id]}` not found")
      exit(1)
    end

    def load_categories
      param_ids = params[:category_ids].split(",").map(&:strip)
      if params[:include_descendants]
        like_conditions = param_ids.map { |id| "id LIKE ?" }.join(" OR ")
        like_values = param_ids.map { |id| "#{id}%" }
        @categories = Category.where(like_conditions, *like_values)
      else
        @categories = Category.where(id: param_ids)
      end
      mapped_ids = @categories.map(&:id)
      return @categories if (param_ids - mapped_ids).empty?

      missing_ids = param_ids - mapped_ids
      logger.fatal("Category IDs `#{missing_ids.join(",")}` not found")
      exit(1)
    end

    def add_to_attribute!
      spinner("Adding Attributes to Categories") do |sp|
        @categories.each do |category|
          if category.related_attributes.include?(@attribute)
            logger.info("Attribute `#{@attribute.friendly_id}` already exists in category `#{category.name}`")
            next
          end

          category.related_attributes << @attribute
          if category.save
            sp.update_title("Added attribute `#{@attribute.friendly_id}` to category `#{category.name}`")
          else
            logger.fatal("Failed to add attribute: #{category.errors.full_messages.to_sentence}")
            exit(1)
          end
        end

        sp.update_title("Added attribute `#{@attribute.friendly_id}` to #{@categories.size} categories")
      end
    end

    def update_data_files!
      roots = @categories.map(&:root).uniq.map(&:id)
      DumpVerticalsCommand.new(verticals: roots, interactive: true, **params.to_h).execute
      SyncEnLocalizationsCommand.new(interactive: true, targets: ["categories"], **params.to_h).execute
      GenerateDocsCommand.new(interactive: true, **params.to_h).execute
    end
  end
end
