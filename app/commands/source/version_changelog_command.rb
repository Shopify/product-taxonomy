# frozen_string_literal: true

module Source
  class VersionChangelogCommand < ApplicationCommand
    usage do
      no_command
    end

    option :version do
      long "--version string"
      desc "The version of the full_names.yml file to compare"
    end

    def execute
      version = params[:version] || latest_version
      frame("Processing categories for version #{version}") do
        ensure_exports_directory
        delete_previous_exports(version)
        process_category_tree
        compare_and_export(version)
      end
    end

    private

    def latest_version
      # Get the list of directories and sort them to find the latest version
      versions = Dir.glob('data/integrations/shopify/*').select do |f|
        File.directory?(f) && f.match(/\d{4}-\d{2}/)
      end.map do |f|
        File.basename(f)
      end.sort

      versions.last
    end

    def ensure_exports_directory
      unless Dir.exist?('exports')
        Dir.mkdir('exports')
        puts "Created 'exports' directory in product-taxonomy"
      end
    end

    def delete_previous_exports(version)
      if File.exist?('exports/category_tree.csv')
        File.delete('exports/category_tree.csv')
        puts "Deleted previous category tree export: exports/category_tree.csv"
      end

      changelog_file = "exports/version_changelog_from_#{version}.csv"
      if File.exist?(changelog_file)
        File.delete(changelog_file)
        puts "Deleted previous version change log export: #{changelog_file}"
      end
    end

    def process_category_tree
      categories_file = 'dist/en/categories.txt'
      categories_data = File.read(categories_file).lines.map(&:strip)

      CSV.open('exports/category_tree.csv', 'w') do |csv|
        csv << ['ID', 'Breadcrumb', 'Vertical Name', 'Category Name']
        categories_data.each do |line|
          # Skip comments and empty lines
          next if line.start_with?('#') || line.empty?

          if line =~ /^gid:\/\/shopify\/TaxonomyCategory\/(\S+)\s*:\s*(.+)$/
            id = $1
            breadcrumb = $2
            vertical_name = extract_vertical_name(breadcrumb)
            category_name = extract_category_name(breadcrumb)
            csv << [id, breadcrumb, vertical_name, category_name]
          else
            logger.warn("Warning: Line format incorrect - #{line}")
          end
        end
      end

      puts "Category data has been written to category_tree.csv"
    end

    def compare_and_export(version)
      full_names_file = "data/integrations/shopify/#{version}/full_names.yml"
      full_names_data = YAML.load_file(full_names_file)
      full_names_hash = full_names_data.each_with_object({}) do |entry, hash|
        hash[entry['id']] = entry['full_name']
      end

      categories_file = 'dist/en/categories.txt'
      categories_data = File.read(categories_file).lines.map(&:strip)
      categories_hash = categories_data.each_with_object({}) do |line, hash|
        # Skip comments and empty lines
        next if line.start_with?('#') || line.empty?

        if line =~ /^gid:\/\/shopify\/TaxonomyCategory\/(\S+)\s*:\s*(.+)$/
          id = $1
          category = $2
          hash[id] = category
        else
          logger.warn("Warning: Line format incorrect - #{line}")
        end
      end

      changelog_file = "exports/version_changelog_from_#{version}.csv"
      CSV.open(changelog_file, 'w') do |csv|
        csv << ['Change Type', 'ID', 'Breadcrumb', 'Vertical Name', 'Category Name', 'Renamed From']
        full_names_hash.each do |id, full_name|
          if categories_hash.key?(id)
            if full_name != categories_hash[id]
              vertical_name = extract_vertical_name(categories_hash[id])
              category_name = extract_category_name(categories_hash[id])
              csv << ['renamed', id, categories_hash[id], vertical_name, category_name, "#{full_name}"]
            end
          else
            vertical_name = extract_vertical_name(full_name)
            category_name = extract_category_name(full_name)
            csv << ['archived', id, full_name, vertical_name, category_name, '']
          end
        end

        categories_hash.each do |id, category|
          unless full_names_hash.key?(id)
            vertical_name = extract_vertical_name(category)
            category_name = extract_category_name(category)
            csv << ['new', id, category, vertical_name, category_name, '']
          end
        end
      end

      puts "Version change log from #{version} has been written to #{changelog_file}"
    end

    def extract_vertical_name(breadcrumb)
      breadcrumb.split(' > ').first
    end

    def extract_category_name(breadcrumb)
      breadcrumb.split(' > ').last
    end
  end
end