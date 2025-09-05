# frozen_string_literal: true

require "csv"
require "yaml"
require "fileutils"

module ProductTaxonomy
  class CompareCategoriesCommand < Command
    def execute(version_folder)
      validate_version_folder!(version_folder)
      
      logger.info("Loading full_names from version: #{version_folder}")
      full_names = load_full_names(version_folder)
      logger.info("Loaded #{full_names.size} categories from full_names.yml")
      
      logger.info("Loading categories from dist/en/categories.txt")
      categories = load_categories
      logger.info("Loaded #{categories.size} categories from categories.txt")
      
      logger.info("Comparing categories...")
      changes = compare_categories(full_names, categories)
      
      # Create output directory if it doesn't exist
      output_dir = File.expand_path(options[:output_dir] || "exports", ProductTaxonomy.data_path)
      FileUtils.mkdir_p(output_dir)
      
      # Write CSV report
      output_path = write_csv_report(changes, version_folder, output_dir)
      
      # Print summary
      logger.info("")
      logger.info("Comparison complete!")
      logger.info("Total changes detected: #{changes.size}")
      
      if changes.any?
        change_types = changes.group_by { |change| change[:type] }
        change_types.each do |change_type, changes_of_type|
          logger.info("  #{change_type.capitalize}s: #{changes_of_type.size}")
        end
        
        logger.info("")
        logger.info("Detailed report saved to: #{output_path}")
      else
        logger.info("No changes detected between the two files.")
      end
    end

    private

    def validate_version_folder!(version_folder)
      full_names_path = File.expand_path(
        "integrations/shopify/#{version_folder}/full_names.yml",
        ProductTaxonomy.data_path
      )
      
      unless File.exist?(full_names_path)
        raise ArgumentError, "full_names.yml not found in #{version_folder}"
      end
    end

    def load_full_names(version_folder)
      full_names_path = File.expand_path(
        "integrations/shopify/#{version_folder}/full_names.yml",
        ProductTaxonomy.data_path
      )
      
      data = YAML.safe_load_file(full_names_path)
      
      # Convert to hash with id as key and full_name as value
      data.each_with_object({}) do |item, hash|
        hash[item["id"]] = item["full_name"]
      end
    end

    def load_categories
      categories_path = File.expand_path("../dist/en/categories.txt", ProductTaxonomy.data_path)
      
      unless File.exist?(categories_path)
        raise ArgumentError, "categories.txt not found in dist/en/"
      end
      
      categories = {}
      
      File.foreach(categories_path) do |line|
        line = line.strip
        next if line.empty? || line.start_with?("#")
        
        # Parse format: gid://shopify/TaxonomyCategory/{id} : {full_name}
        if line.include?(" : ")
          gid_part, full_name = line.split(" : ", 2)
          
          # Extract ID by removing the gid://shopify/TaxonomyCategory/ prefix
          if gid_part.start_with?("gid://shopify/TaxonomyCategory/")
            category_id = gid_part.gsub("gid://shopify/TaxonomyCategory/", "").strip
            categories[category_id] = full_name.strip
          end
        end
      end
      
      categories
    end

    def compare_categories(full_names, categories)
      changes = []
      
      # Get all unique IDs from both sources
      all_ids = (full_names.keys + categories.keys).uniq.sort
      
      all_ids.each do |category_id|
        in_full_names = full_names.key?(category_id)
        in_categories = categories.key?(category_id)
        
        if in_full_names && in_categories
          # Check for renames (same ID, different name)
          if full_names[category_id] != categories[category_id]
            changes << {
              type: :rename,
              id: category_id,
              old_name: full_names[category_id],
              new_name: categories[category_id]
            }
          end
        elsif in_full_names && !in_categories
          # Archived (exists in full_names but not in categories)
          changes << {
            type: :archived,
            id: category_id,
            old_name: full_names[category_id],
            new_name: ""
          }
        elsif !in_full_names && in_categories
          # Addition (exists in categories but not in full_names)
          changes << {
            type: :addition,
            id: category_id,
            old_name: "",
            new_name: categories[category_id]
          }
        end
      end
      
      changes
    end

    def write_csv_report(changes, version_folder, output_dir)
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      filename = "category_changes_#{version_folder}_#{timestamp}.csv"
      output_path = File.join(output_dir, filename)
      
      CSV.open(output_path, "w", encoding: "utf-8") do |csv|
        csv << %w[type id old_name new_name]
        changes.each do |change|
          csv << [
            change[:type],
            change[:id],
            change[:old_name],
            change[:new_name]
          ]
        end
      end
      
      output_path
    end
  end
end
