require 'yaml'

# Read the YAML file
file_path = 'data/attributes.yml'
yaml_content = File.read(file_path)

# Parse the YAML content
data = YAML.safe_load(yaml_content)

# Function to sort entries by id recursively
def sort_by_id(data)
  data.each do |entry|
    if entry.is_a?(Array)
      entry.each do |sub_entry|
        if sub_entry.is_a?(Array)
          sub_entry.sort_by! { |item| item['id'] if item.is_a?(Hash) && item.key?('id') }
        end
      end
    end
  end
end

# Sort the data by id
sort_by_id(data)

# Write the modified data back to the YAML file
File.open(file_path, 'w') { |file| file.write(data.to_yaml(line_width: -1)) }