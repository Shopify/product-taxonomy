# frozen_string_literal: true

module Source
  class DumpValuesCommand < ApplicationCommand
    usage do
      no_command
    end

    def execute
      frame("Dumping values") do
        update_values_file
      end
    end

    private

    def update_values_file
      spinner("Updating values.yml") do |sp|
        sys.write_file!("data/values.yml") do |file|
          file.write(YamlSerializer.dump(Value.as_json_for_data))
        end
        sp.update_title("Updated data/values.yml")
      end
    end
  end
end
