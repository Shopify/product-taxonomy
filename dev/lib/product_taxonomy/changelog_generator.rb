# frozen_string_literal: true

require "set"
require "yaml"

module ProductTaxonomy
  class ChangelogGenerator
    DEFAULT_EXAMPLE_LIMIT = 5
    DEFAULT_ATTRIBUTE_LIMIT = 4
    LOCALE_NAMES = {
      "bg-BG" => "Bulgarian",
      "cs" => "Czech",
      "da" => "Danish",
      "de" => "German",
      "el" => "Greek",
      "es" => "Spanish",
      "fi" => "Finnish",
      "fr" => "French",
      "hi" => "Hindi",
      "hr-HR" => "Croatian",
      "hu" => "Hungarian",
      "id-ID" => "Indonesian",
      "it" => "Italian",
      "ja" => "Japanese",
      "ko" => "Korean",
      "lt-LT" => "Lithuanian",
      "nb" => "Norwegian Bokmål",
      "nl" => "Dutch",
      "pl" => "Polish",
      "pt-BR" => "Portuguese (Brazil)",
      "pt-PT" => "Portuguese (Portugal)",
      "ro-RO" => "Romanian",
      "ru" => "Russian",
      "sk-SK" => "Slovak",
      "sl-SI" => "Slovenian",
      "sv" => "Swedish",
      "th" => "Thai",
      "tr" => "Turkish",
      "vi" => "Vietnamese",
      "zh-CN" => "Chinese (Simplified)",
      "zh-TW" => "Chinese (Traditional)",
    }.freeze
    LOCALIZATION_TYPE_NAMES = {
      "categories" => "category",
      "attributes" => "attribute",
      "values" => "value",
    }.freeze

    def initialize(base_path:, head_path:, vertical_notes: {}, additional_sections: {})
      @base_path = File.expand_path(base_path)
      @head_path = File.expand_path(head_path)
      @vertical_notes = vertical_notes
      @additional_sections = additional_sections
    end

    def generate
      validate_paths!
      load_taxonomies

      lines = taxonomy_summary
      localization_lines = localization_summary
      lines.concat(localization_lines) unless localization_lines.empty?
      lines.concat(additional_section_lines)
      lines.pop while lines.last == ""
      lines.join("\n") + "\n"
    end

    private

    def validate_paths!
      [@base_path, @head_path].each do |path|
        required_files = ["data/attributes.yml", "data/categories"]
        missing = required_files.reject { |relative_path| File.exist?(File.join(path, relative_path)) }
        raise ArgumentError, "Not a taxonomy checkout: #{path}" unless missing.empty?
      end
    end

    def load_taxonomies
      @base_attribute_data, @base_attributes, @base_categories = load_data(@base_path)
      @head_attribute_data, @head_attributes, @head_categories = load_data(@head_path)
      @new_category_ids = @head_categories.keys.to_set - @base_categories.keys.to_set
      @new_attribute_ids = @head_attributes.keys.to_set - @base_attributes.keys.to_set
      @parent = build_parent_index
      @subtree_size = {}
    end

    def load_data(root)
      attribute_data = yaml(File.join(root, "data/attributes.yml"))
      attributes = (attribute_data.fetch("base_attributes") + attribute_data.fetch("extended_attributes")).to_h do |attribute|
        [attribute.fetch("friendly_id"), attribute]
      end
      categories = Dir[File.join(root, "data/categories/*.yml")].sort.flat_map { |path| yaml(path) }.to_h do |category|
        [category.fetch("id"), category]
      end
      [attribute_data, attributes, categories]
    end

    def yaml(path)
      YAML.safe_load_file(path)
    end

    def taxonomy_summary
      category_noun = @new_category_ids.size == 1 ? "category" : "categories"
      attribute_count = new_base_attribute_count
      attribute_noun = attribute_count == 1 ? "base attribute" : "base attributes"
      lines = [
        "#### 📚 Taxonomy Tree",
        "",
        "Expands the taxonomy with #{number(@new_category_ids.size)} new #{category_noun} and " \
          "#{number(attribute_count)} new #{attribute_noun} with closed lists of values.",
        "",
      ]

      verticals.each do |vertical|
        vertical_lines = vertical_summary(vertical)
        lines.concat(vertical_lines) unless vertical_lines.empty?
      end
      lines
    end

    def new_base_attribute_count
      base_ids = @base_attribute_data.fetch("base_attributes").to_h { |attribute| [attribute.fetch("friendly_id"), true] }
      @head_attribute_data.fetch("base_attributes").count do |attribute|
        !base_ids.key?(attribute.fetch("friendly_id"))
      end
    end

    def verticals
      @head_categories.values.select { |category| !category.fetch("id").include?("-") }
    end

    def vertical_summary(vertical)
      vertical_id = vertical.fetch("id")
      categories = @head_categories.values.select do |category|
        category.fetch("id") == vertical_id || category.fetch("id").start_with?("#{vertical_id}-")
      end
      new_categories = categories.select { |category| @new_category_ids.include?(category.fetch("id")) }
      notes = Array(@vertical_notes[vertical_id])
      assignment_line = existing_category_assignment_summary(vertical_id, categories)
      return [] if new_categories.empty? && notes.empty? && assignment_line.nil?

      lines = ["##### #{vertical.fetch("name")}", ""]
      lines << "- Adds #{number(new_categories.size)} categories in this vertical." unless new_categories.empty?
      notes.each { |note| lines << "- #{note}" }

      unless new_categories.empty?
        groups = new_categories.group_by { |category| nearest_existing_ancestor(category.fetch("id")) }
        selected_groups = select_groups(groups, new_categories.size)
        selected_groups.each { |ancestor_id, grouped_categories| lines << group_summary(ancestor_id, grouped_categories) }

        omitted_groups = groups.keys - selected_groups.map(&:first)
        unless omitted_groups.empty?
          omitted_count = omitted_groups.sum { |ancestor_id| groups.fetch(ancestor_id).size }
          lines << "- Adds another #{number(omitted_count)} categories across " \
            "#{number(omitted_groups.size)} smaller areas in this vertical."
        end
      end

      lines << assignment_line if assignment_line
      lines << ""
      lines
    end

    def select_groups(groups, category_count)
      limit = (category_count / 175.0).ceil.clamp(3, 30)
      groups.sort_by do |ancestor_id, categories|
        ancestor_depth = ancestor_id ? ancestor_id.split("-").size : 0
        [-categories.size, ancestor_depth, ancestor_id.to_s]
      end.first(limit)
    end

    def group_summary(ancestor_id, categories)
      ancestor_name = ancestor_id ? @head_categories.fetch(ancestor_id).fetch("name") : "this vertical"
      category_ids = categories.to_h { |category| [category.fetch("id"), true] }
      representatives = categories.select do |category|
        !category_ids.key?(@parent[category.fetch("id")])
      end.sort_by do |category|
        [-subtree_size(category.fetch("id")), category.fetch("name")]
      end.map { |category| category.fetch("name") }
      representatives = categories.sort_by { |category| [category.fetch("id").split("-").size, category.fetch("name")] }
        .map { |category| category.fetch("name") } if representatives.empty?

      attribute_names = representative_attribute_names(categories)
      count_text = categories.one? ? "one category" : "#{number(categories.size)} categories"
      line = "- In the #{ancestor_name} area, adds #{count_text}, including " \
        "#{formatted_list(representatives, limit: DEFAULT_EXAMPLE_LIMIT)}."
      unless attribute_names.empty?
        noun = attribute_names.one? ? "attribute" : "attributes"
        line += " Adds the #{noun} #{formatted_list(attribute_names, limit: DEFAULT_ATTRIBUTE_LIMIT)} " \
          "to products in this area."
      end
      line
    end

    def representative_attribute_names(categories)
      counts = Hash.new(0)
      categories.each do |category|
        Array(category["attributes"]).each do |attribute_id|
          counts[attribute_id] += 1 if @new_attribute_ids.include?(attribute_id)
        end
      end
      counts.sort_by { |attribute_id, count| [-count, @head_attributes.fetch(attribute_id).fetch("name")] }
        .first(DEFAULT_ATTRIBUTE_LIMIT)
        .map { |attribute_id, _| @head_attributes.fetch(attribute_id).fetch("name") }
    end

    def existing_category_assignment_summary(vertical_id, categories)
      old_pairs = @base_categories.values.select do |category|
        category.fetch("id") == vertical_id || category.fetch("id").start_with?("#{vertical_id}-")
      end.flat_map do |category|
        Array(category["attributes"]).map { |attribute_id| [category.fetch("id"), attribute_id] }
      end.to_set

      new_pairs = categories.select { |category| @base_categories.key?(category.fetch("id")) }.flat_map do |category|
        Array(category["attributes"]).filter_map do |attribute_id|
          pair = [category.fetch("id"), attribute_id]
          pair unless old_pairs.include?(pair)
        end
      end
      return if new_pairs.empty?

      affected_categories = new_pairs.map(&:first).uniq.size
      category_noun = affected_categories == 1 ? "category" : "categories"
      assignment_noun = new_pairs.size == 1 ? "attribute assignment" : "attribute assignments"
      "- Adds #{number(new_pairs.size)} #{assignment_noun} across #{number(affected_categories)} " \
        "existing #{category_noun} in this vertical."
    end

    def build_parent_index
      @head_categories.each_value.with_object({}) do |category, index|
        Array(category["children"]).each { |child_id| index[child_id] = category.fetch("id") }
      end
    end

    def nearest_existing_ancestor(category_id)
      current = @parent[category_id]
      current = @parent[current] while current && @new_category_ids.include?(current)
      current
    end

    def subtree_size(category_id)
      @subtree_size[category_id] ||= 1 + Array(@head_categories.fetch(category_id)["children"]).sum do |child_id|
        subtree_size(child_id)
      end
    end

    def localization_summary
      locale_changes = changed_locales
      return [] if locale_changes.empty?

      new_locales = locale_changes.select { |change| change.fetch(:new) }.map { |change| change.fetch(:locale) }
      changed_type_set = locale_changes.flat_map { |change| change.fetch(:types) }.to_set
      changed_types = LOCALIZATION_TYPE_NAMES.keys.select { |type| changed_type_set.include?(type) }
      type_names = changed_types.map { |type| LOCALIZATION_TYPE_NAMES.fetch(type, type) }
      language_noun = locale_changes.size == 1 ? "non-English language" : "non-English languages"
      details = []
      unless new_locales.empty?
        locale_names = new_locales.sort.map { |locale| LOCALE_NAMES.fetch(locale, locale) }
        details << "adds #{plain_list(locale_names)}"
      end
      details << "refreshes #{plain_list(type_names)} translations across " \
        "#{number(locale_changes.size)} #{language_noun}"
      sentence = details.join(" and ").sub(/\A[a-z]/, &:upcase)
      ["#### 🌐 Localization", "", "- #{sentence}.", ""]
    end

    def changed_locales
      head_files = localization_files(@head_path)
      base_files = localization_files(@base_path)
      (head_files.keys - ["en"]).sort.filter_map do |locale|
        head_paths = head_files.fetch(locale)
        base_paths = base_files[locale]
        changed_types = head_paths.filter_map do |type, head_path|
          base_path = base_paths&.fetch(type, nil)
          type if base_path.nil? || File.binread(head_path) != File.binread(base_path)
        end
        { locale: locale, new: base_paths.nil?, types: changed_types } unless changed_types.empty?
      end
    end

    def localization_files(root)
      Dir[File.join(root, "data/localizations/{attributes,categories,values}/*.yml")].each_with_object({}) do |path, files|
        locale = File.basename(path, ".yml")
        type = File.basename(File.dirname(path))
        files[locale] ||= {}
        files[locale][type] = path
      end
    end

    def additional_section_lines
      @additional_sections.flat_map do |heading, notes|
        ["#### #{heading}", "", *Array(notes).map { |note| "- #{note}" }, ""]
      end
    end

    def number(value)
      value.to_s.reverse.scan(/.{1,3}/).join(",").reverse
    end

    def plain_list(items)
      return "" if items.empty?
      return items.first if items.one?
      return items.join(" and ") if items.size == 2

      "#{items[0...-1].join(", ")} and #{items.last}"
    end

    def formatted_list(items, limit: DEFAULT_EXAMPLE_LIMIT)
      shown = items.uniq.first(limit).map { |item| "`#{item}`" }
      return "" if shown.empty?
      return shown.first if shown.one?
      return shown.join(" and ") if shown.size == 2

      "#{shown[0...-1].join(", ")} and #{shown.last}"
    end
  end
end
