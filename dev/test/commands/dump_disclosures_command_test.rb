# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class DumpDisclosuresCommandTest < TestCase
    setup do
      @tmp_base_path = Dir.mktmpdir

      FileUtils.mkdir_p(File.expand_path("data", @tmp_base_path))
      ProductTaxonomy.stubs(:data_path).returns(File.expand_path("data", @tmp_base_path))

      Command.any_instance.stubs(:load_taxonomy)
    end

    teardown do
      FileUtils.remove_entry(@tmp_base_path)
    end

    test "execute dumps disclosures to YAML file" do
      mock_data = [
        {
          "id" => 1,
          "public_id" => "choking_hazard",
          "parent_public_id" => nil,
          "name" => "Choking hazards",
          "internal_label" => "Choking hazards",
        },
        {
          "id" => 2,
          "public_id" => "us-cpsc-choking_small_parts",
          "parent_public_id" => "choking_hazard",
          "name" => "Choking Hazard — Small Parts (US)",
          "internal_label" => "Choking Hazard — Small Parts (US)",
        },
      ]
      Serializers::Disclosure::Data::DataSerializer.stubs(:serialize_all)
        .returns(mock_data)

      command = DumpDisclosuresCommand.new({})
      command.execute

      expected_path = File.expand_path("data/disclosures.yml", @tmp_base_path)
      assert File.exist?(expected_path)

      dumped_data = YAML.load_file(expected_path)
      assert_equal mock_data, dumped_data
    end

    test "execute preserves the header and section comments of the existing file" do
      existing = <<~YAML
        ---
        # Disclosures.
        #
        # Authoring rules live here — never rename an existing `public_id`.

        # Choking hazards
        - id: 1
          public_id: choking_hazard

        # Chemical exposures
        - id: 12
          public_id: chemical_exposure
      YAML
      path = File.expand_path("data/disclosures.yml", @tmp_base_path)
      File.write(path, existing)

      mock_data = [
        { "id" => 1, "public_id" => "choking_hazard" },
        { "id" => 12, "public_id" => "chemical_exposure" },
      ]
      Serializers::Disclosure::Data::DataSerializer.stubs(:serialize_all).returns(mock_data)

      DumpDisclosuresCommand.new({}).execute

      output = File.read(path)
      expected = <<~YAML
        ---
        # Disclosures.
        #
        # Authoring rules live here — never rename an existing `public_id`.

        # Choking hazards
        - id: 1
          public_id: choking_hazard

        # Chemical exposures
        - id: 12
          public_id: chemical_exposure
      YAML
      assert_equal expected, output
      assert_equal mock_data, YAML.load_file(path)
    end

    test "execute drops comments attached to entries that no longer exist" do
      existing = <<~YAML
        ---
        # Header comment.

        # Section for a removed entry
        - id: 99
          public_id: removed
      YAML
      path = File.expand_path("data/disclosures.yml", @tmp_base_path)
      File.write(path, existing)

      mock_data = [{ "id" => 1, "public_id" => "choking_hazard" }]
      Serializers::Disclosure::Data::DataSerializer.stubs(:serialize_all).returns(mock_data)

      DumpDisclosuresCommand.new({}).execute

      output = File.read(path)
      assert_includes output, "# Header comment."
      refute_includes output, "# Section for a removed entry"
      assert_equal mock_data, YAML.load_file(path)
    end

    test "execute creates directory if it doesn't exist" do
      FileUtils.rm_rf(File.expand_path("data", @tmp_base_path))

      mock_data = { "test" => "data" }
      Serializers::Disclosure::Data::DataSerializer.stubs(:serialize_all)
        .returns(mock_data)

      command = DumpDisclosuresCommand.new({})
      command.execute

      expected_path = File.expand_path("data/disclosures.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      assert File.directory?(File.dirname(expected_path))
    end
  end
end
