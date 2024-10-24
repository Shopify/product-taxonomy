# frozen_string_literal: true

module Source
  class DumpAttributesCommand < ApplicationCommand
    usage do
      no_command
    end

    def execute
      frame("Dumping attributes") do
        update_attributes_file
      end
    end

    private

    def update_attributes_file
      spinner("Updating attributes.yml") do |sp|
        sys.write_file!("data/attributes.yml") do |file|
          file.write(YamlSerializer.dump(Attribute.as_json_for_data))
        end
        sp.update_title("Updated data/attributes.yml")
      end
    end
  end
end
