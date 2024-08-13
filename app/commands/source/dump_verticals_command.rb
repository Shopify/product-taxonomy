# frozen_string_literal: true

module Source
  class DumpVerticalsCommand < ApplicationCommand
    usage do
      no_command
    end

    option :verticals do
      desc "Verticals to export to data/"
      long "--verticals list"
      convert :list
      default -> { Category.verticals.pluck(:id).join(",") }
      validate -> { Category.verticals.pluck(:id).include?(_1) }
    end

    def execute
      frame("Dumping #{params[:verticals].size} verticals") do
        params[:verticals].each do |vertical_id|
          update_vertical_file(vertical_id)
        end
      end
    end

    private

    def update_vertical_file(vertical_id)
      vertical = Category.find_by!(id: vertical_id)
      spinner("Updating `#{vertical.name}`") do |sp|
        path = "data/categories/#{vertical.friendly_name}.yml"
        sys.write_file!(path) do |file|
          file.write(vertical.as_json_for_data_with_descendants.to_yaml(line_width: -1))
        end
        sp.update_title("Updated `#{path}`")
      end
    end
  end
end
