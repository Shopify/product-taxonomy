# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class ChangelogGeneratorTest < TestCase
    setup do
      @temporary_directory = Dir.mktmpdir
      @base_path = File.join(@temporary_directory, "base")
      @head_path = File.join(@temporary_directory, "head")
      write_taxonomy(@base_path, head: false)
      write_taxonomy(@head_path, head: true)
    end

    teardown do
      FileUtils.remove_entry(@temporary_directory)
    end

    test "#generate creates a deterministic summary from taxonomy source data" do
      output = generator.generate

      assert_includes(output, "Expands the taxonomy with 2 new categories and 1 new base attribute")
      assert_includes(output, "##### Apparel & Accessories")
      assert_includes(output, "- Adds 2 categories in this vertical.")
      assert_includes(
        output,
        "- In the Clothing area, adds 2 categories, including `Coats` and `Shirts`. " \
          "Adds the attribute `Usage` to products in this area.",
      )
      assert_includes(output, "- Adds 1 attribute assignment across 1 existing category in this vertical.")
      assert_equal(output, generator.generate)
    end

    test "#generate includes affected verticals for attribute-only releases" do
      head_categories = categories(head: false)
      head_categories.find { |category| category.fetch("id") == "aa-2" }.fetch("attributes") << "usage"
      write_yaml(@head_path, "data/categories/aa.yml", head_categories)

      output = ChangelogGenerator.new(
        base_path: @base_path,
        head_path: @head_path,
        vertical_notes: { "aa" => ["Adds a reviewed attribute model."] },
      ).generate

      assert_includes(output, "##### Apparel & Accessories")
      assert_includes(output, "- Adds a reviewed attribute model.")
      assert_includes(output, "- Adds 1 attribute assignment across 1 existing category in this vertical.")
      refute_includes(output, "- Adds 0 categories in this vertical.")
    end

    test "#generate reports inferred localization changes" do
      output = generator.generate

      assert_includes(output, "#### 🌐 Localization")
      assert_includes(
        output,
        "- Adds Hindi and refreshes category, attribute and value translations across 2 non-English languages.",
      )
    end

    test "#generate includes explicitly reviewed manual notes" do
      output = ChangelogGenerator.new(
        base_path: @base_path,
        head_path: @head_path,
        vertical_notes: { "aa" => ["Renames a reviewed category area."] },
        additional_sections: { "📦 Distribution" => ["Publishes reviewed release assets."] },
      ).generate

      assert_includes(output, "- Renames a reviewed category area.")
      assert_includes(output, "#### 📦 Distribution\n\n- Publishes reviewed release assets.")
    end

    test "#generate raises when a path is not a taxonomy checkout" do
      error = assert_raises(ArgumentError) do
        ChangelogGenerator.new(base_path: @temporary_directory, head_path: @head_path).generate
      end

      assert_equal("Not a taxonomy checkout: #{@temporary_directory}", error.message)
    end

    private

    def generator
      ChangelogGenerator.new(base_path: @base_path, head_path: @head_path)
    end

    def write_taxonomy(root, head:)
      write_yaml(
        root,
        "data/attributes.yml",
        {
          "base_attributes" => [
            attribute(1, "Material", "material"),
            *(head ? [attribute(2, "Usage", "usage")] : []),
          ],
          "extended_attributes" => [],
        },
      )
      write_yaml(root, "data/categories/aa.yml", categories(head: head))
      write_localizations(root, head: head)
    end

    def attribute(id, name, friendly_id)
      {
        "id" => id,
        "name" => name,
        "description" => "Description",
        "friendly_id" => friendly_id,
        "handle" => friendly_id,
        "values" => ["#{friendly_id}__other"],
      }
    end

    def categories(head:)
      categories = [
        { "id" => "aa", "name" => "Apparel & Accessories", "children" => ["aa-1", "aa-2"] },
        {
          "id" => "aa-1",
          "name" => "Clothing",
          "children" => head ? ["aa-1-1", "aa-1-2"] : [],
          "attributes" => ["material"],
        },
        {
          "id" => "aa-2",
          "name" => "Accessories",
          "children" => [],
          "attributes" => head ? ["material", "usage"] : ["material"],
        },
      ]
      return categories unless head

      categories + [
        { "id" => "aa-1-1", "name" => "Shirts", "children" => [], "attributes" => ["material", "usage"] },
        { "id" => "aa-1-2", "name" => "Coats", "children" => [], "attributes" => ["material", "usage"] },
      ]
    end

    def write_localizations(root, head:)
      ["attributes", "categories", "values"].each do |type|
        write_yaml(root, "data/localizations/#{type}/en.yml", { "en" => { type => { "key" => { "name" => "English" } } } })
        french = head ? "Français mis à jour" : "Français"
        write_yaml(root, "data/localizations/#{type}/fr.yml", { "fr" => { type => { "key" => { "name" => french } } } })
        next unless head

        write_yaml(root, "data/localizations/#{type}/hi.yml", { "hi" => { type => { "key" => { "name" => "हिन्दी" } } } })
      end
    end

    def write_yaml(root, relative_path, contents)
      path = File.join(root, relative_path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, YAML.dump(contents))
    end
  end
end
