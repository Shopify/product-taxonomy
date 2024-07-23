# frozen_string_literal: true

# TODO: make this use our models instead of loading from YAML
#       will let us simplify this a lot
class SyncEnLocalizationsCommand < ApplicationCommand
  usage do
    no_command
  end

  def execute
    frame("Syncing EN localizations") do
      sync_categories
      sync_attributes
      sync_values
    end
  end

  private

  def sync_categories
    spinner("Syncing categories") do |sp|
      categories = load_categories
      localizations = build_category_localizations(categories)
      write_localizations("categories", localizations, sp)
    end
  end

  def sync_attributes
    spinner("Syncing attributes") do |sp|
      attributes = load_attributes
      localizations = build_attribute_localizations(attributes)
      write_localizations("attributes", localizations, sp)
    end
  end

  def sync_values
    spinner("Syncing values") do |sp|
      attributes = load_attributes
      values = load_values
      localizations = build_value_localizations(attributes, values)
      write_localizations("values", localizations, sp)
    end
  end

  def write_localizations(type, localizations, sp)
    file_path = "data/localizations/#{type}/en.yml"
    sys.write_file!(file_path) do |file|
      file.write("# This file is auto-generated using bin/sync_en_localizations. Do not edit directly.\n")
      file.write(localizations.to_yaml(line_width: -1))
    end
    sp.update_title("Written #{type} localizations to #{file_path}")
  end

  # TODO: delete me
  def load_categories
    categories = {}
    sys.glob("data/categories/*.yml").each do |file|
      sys.parse_yaml(file).each do |category|
        categories[category["id"]] = { name: category["name"], context: "" }
      end
    end
    categories
  end

  # TODO: move me to model, and then delete me
  def build_category_localizations(categories)
    categories.each_key do |id|
      categories[id][:context] = build_full_name(id, categories)
    end

    localizations = { "en" => { "categories" => {} } }
    category_sort(categories).each do |id, details|
      localizations["en"]["categories"][id] = { "name" => details[:name], "context" => details[:context] }
    end
    localizations
  end

  # TODO: delete me
  def build_full_name(id, categories)
    parts = id.split("-")
    full_name = []
    parts.each_with_index do |_, index|
      partial_id = parts[0..index].join("-")
      full_name << categories[partial_id][:name] if categories.key?(partial_id)
    end
    full_name.join(" > ")
  end

  # TODO: delete me
  def category_sort(items)
    items.sort_by do |id, _|
      id.split("-").map { |part| part.match?(/\d+/) ? part.to_i : part }
    end
  end

  # TODO: delete me
  def load_attributes
    @attributes ||= sys.parse_yaml("data/attributes.yml").values.flatten
  end

  # TODO: move me to model, and then delete me
  def build_attribute_localizations(attributes)
    localizations = { "en" => { "attributes" => {} } }
    attributes.sort_by { _1["friendly_id"] }.each do |attribute|
      localizations["en"]["attributes"][attribute["friendly_id"]] = {
        "name" => attribute["name"],
        "description" => attribute["description"],
      }
    end
    localizations
  end

  # TODO: delete me
  def load_values
    @values ||= sys.parse_yaml("data/values.yml")
  end

  # TODO: move me to model, and then delete me
  def build_value_localizations(attributes, values)
    attributes_by_friendly = attributes.map { |a| [a["friendly_id"], a] }.to_h

    localizations = { "en" => { "values" => {} } }
    values.sort_by { _1["friendly_id"] }.each do |value|
      attribute = attributes_by_friendly[value["friendly_id"].split("__").first]
      next unless attribute

      localizations["en"]["values"][value["friendly_id"]] = {
        "name" => value["name"],
        "context" => attribute["name"],
      }
    end
    localizations
  end
end
