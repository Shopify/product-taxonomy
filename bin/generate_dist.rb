require 'yaml'
require 'date'

class GenerateDist
  class << self
    def humanize(string)
      string.split("_").map(&:capitalize).join(" ")
    end

    def generate_category_txt
      categories = {}
      Dir.glob('src/shopify/categories/*.yml').each do |file|
        file_name = File.basename(file, ".yml")
        data = YAML.load_file(file)
        categories[file_name] = data.map{ "#{_1["public_id"]}: #{_1["fully_qualified_type"]}"}
      end

      categories.each do |filename, data|
        File.open("dist/shopify/categories/#{filename}.txt", 'w') do |file|
          file.write("# Shopify #{humanize(filename)} Product Taxonomy: #{Date.today} \n")
          file.write(data.join("\n"))
        end
      end

      File.open("dist/shopify/categories.txt", "w") do |file|
        file.write("# Shopify Product Taxonomy: #{Date.today} \n")
        file.write(categories.values.flatten.join("\n"))
      end
    end
  end
end

GenerateDist.generate_category_txt
