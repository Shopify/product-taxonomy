require 'yaml'

# Read the YAML file
file_path = 'data/values.yml'
yaml_content = File.read(file_path)

# Parse the YAML content
data = YAML.safe_load(yaml_content)

# Function to sort entries by id
def sort_by_id(data)
  data.sort_by! { |entry| entry['id'] if entry.is_a?(Hash) && entry.key?('id') }
end

# Sort the data by id
sorted_data = sort_by_id(data)

# Write the modified data back to the YAML file
File.open(file_path, 'w') { |file| file.write(sorted_data.to_yaml(line_width: -1)) }