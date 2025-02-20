# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Category
      module Dist
        class TxtSerializerTest < TestCase
          setup do
            @root = ProductTaxonomy::Category.new(id: "aa", name: "Root")
            @child = ProductTaxonomy::Category.new(id: "aa-1", name: "Child")
            @root.add_child(@child)
            @grandchild = ProductTaxonomy::Category.new(id: "aa-1-1", name: "Grandchild")
            @child.add_child(@grandchild)
          end

          test "serialize returns the TXT representation of the category" do
            assert_equal "gid://shopify/TaxonomyCategory/aa : Root", TxtSerializer.serialize(@root, padding: 0)
          end

          test "serialize returns the localized TXT representation of the category" do
            stub_localizations

            actual_txt = TxtSerializer.serialize(@root, padding: 0, locale: "fr")
            assert_equal "gid://shopify/TaxonomyCategory/aa : Root en français", actual_txt
          end

          test "serialize_all returns the TXT representation of all categories with correct padding" do
            stub_localizations
            ProductTaxonomy::Category.stubs(:verticals).returns([@root])
            ProductTaxonomy::Category.add(@root)
            ProductTaxonomy::Category.add(@child)
            ProductTaxonomy::Category.add(@grandchild)

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Categories: 1.0
              # Format: {GID} : {Ancestor name} > ... > {Category name}

              gid://shopify/TaxonomyCategory/aa     : Root
              gid://shopify/TaxonomyCategory/aa-1   : Root > Child
              gid://shopify/TaxonomyCategory/aa-1-1 : Root > Child > Grandchild
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
          end

          private

          def stub_localizations
            fr_yaml = <<~YAML
              fr:
                categories:
                  aa:
                    name: "Root en français"
                  aa-1:
                    name: "Child en français"
                  aa-1-1:
                    name: "Grandchild en français"
            YAML
            es_yaml = <<~YAML
              es:
                categories:
                  aa:
                    name: "Root en español"
                  aa-1:
                    name: "Child en español"
                  aa-1-1:
                    name: "Grandchild en español"
            YAML
            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "categories", "*.yml"))
              .returns(["fake/path/fr.yml", "fake/path/es.yml"])
            YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
            YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "attributes", "*.yml"))
              .returns([])
            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "values", "*.yml"))
              .returns([])
          end
        end
      end
    end
  end
end
