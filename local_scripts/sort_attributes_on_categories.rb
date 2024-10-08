require 'yaml'

# Read the YAML file
file_path = 'data/categories/bt_baby_toddler.yml'
yaml_content = File.read(file_path)

# Parse the YAML content
data = YAML.safe_load(yaml_content)

# Function to sort attributes
def sort_attributes(data)
  data.each do |category|
    if category['attributes']
      category['attributes'].sort!
    end
    # Recursively sort attributes for children
    sort_attributes(category['children']) if category['children']
  end
end

# Sort the attributes
sort_attributes(data)

# Write the modified data back to the YAML file
File.open(file_path, 'w') { |file| file.write(data.to_yaml(line_width: -1)) }