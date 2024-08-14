# frozen_string_literal: true

class GenerateDistCommand < ApplicationCommand
  usage do
    no_command
  end

  option :version do
    desc "Distribution version"
    long "--version string"
  end

  option :locales do
    desc "Locales to generate"
    long "--locales list"
    default "en"
    convert -> { _1.downcase.split(",") }
  end

  def execute
    setup_options
    frame("Generating distribution files") do
      logger.headline("Version: #{params[:version]}")
      logger.headline("Locales: #{params[:locales].join(", ")}")

      params[:locales].each { generate_dist_files(_1) }
    end
  end

  private

  def setup_options
    params[:version] ||= sys.read_file("VERSION").strip
    if params[:locales].include?("all")
      params[:locales] = sys.glob("data/localizations/categories/*.yml").map { File.basename(_1, ".yml") }
    end
  end

  def generate_dist_files(locale)
    frame("Generating files for {{bold:#{locale}}}", color: :magenta) do
      generate_txt_files(locale)
      generate_json_files(locale)
      generate_mapping_files(locale) if locale == "en"
    end
  end

  def generate_txt_files(locale)
    frame("Generating txt files") do
      ["categories", "attributes", "attribute_values"].each do |type|
        spinner("Generating #{type}.txt") do |sp|
          txt_data = case type
          when "categories" then Category.as_txt(Category.verticals, version: params[:version], locale:)
          when "attributes" then Attribute.as_txt(Attribute.base, version: params[:version], locale:)
          when "attribute_values" then Value.as_txt(Value.all, version: params[:version], locale:)
          end

          sys.write_file!("dist/#{locale}/#{type}.txt") do |file|
            file.write(txt_data)
            file.write("\n")
          end
          sp.update_title("Generated #{type}.txt")
        end
      end
    end
  end

  def generate_json_files(locale)
    frame("Generating json files") do
      # cache json data to avoid duplicate work; but lazy initialize to keep CLI snappy
      categories_json = nil
      attributes_json = nil

      ["categories", "attributes", "taxonomy", "attribute_values"].each do |type|
        spinner("Generating #{type}.json") do |sp|
          json_data = case type
          when "categories"
            categories_json ||= Category.as_json(Category.verticals, version: params[:version], locale:)
          when "attributes"
            attributes_json ||= Attribute.as_json(Attribute.base, version: params[:version], locale:)
          when "taxonomy"
            categories_json.merge(attributes_json)
          when "attribute_values"
            Value.as_json(Value.all, version: params[:version], locale:)
          end

          sys.write_file!("dist/#{locale}/#{type}.json") do |file|
            file.write(JSON.pretty_generate(json_data))
            file.write("\n")
          end
          sp.update_title("Generated #{type}.json")
        end
      end
    end
  end

  def generate_mapping_files(locale)
    frame("Generating mapping files") do
      spinner("Generating all_mappings.json") do |sp|
        sys.write_file!("dist/#{locale}/integrations/all_mappings.json") do |file|
          file.write(JSON.pretty_generate(MappingRule.as_json(MappingRule.all, version: params[:version])))
          file.write("\n")
        end
        sp.update_title("Generated all_mappings.json")
      end

      mapping_groups = MappingRule.all.group_by { |record| [record.input_version, record.output_version] }
      mapping_groups.each do |_, records|
        generate_mapping_group_files(locale, records)
      end
    end
  end

  def generate_mapping_group_files(locale, records)
    directory_path = "dist/#{locale}/integrations/#{records.first.integration.name}"
    sys.delete_files!(directory_path)

    input_version = records.first.input_version.gsub("/", "_")
    output_version = records.first.output_version.gsub("/", "_")
    if input_version.include?("-unstable")
      input_version = input_version.delete_suffix("-unstable")
    end

    if output_version.include?("-unstable")
      output_version = output_version.delete_suffix("-unstable")
    end

    ["txt", "json"].each do |ext|
      spinner("Generating #{input_version}_to_#{output_version}.#{ext}") do |sp|
        sys.write_file!("#{directory_path}/#{input_version}_to_#{output_version}.#{ext}") do |file|
          data = case ext
          when "txt" then MappingRule.as_txt(records, version: params[:version])
          when "json" then JSON.pretty_generate(MappingRule.as_json(records, version: params[:version]))
          end

          file.write(data)
          file.write("\n")
        end
        sp.update_title("Generated #{input_version}_to_#{output_version}.#{ext}")
      end
    end
  end
end
