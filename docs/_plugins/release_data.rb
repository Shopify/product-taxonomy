# frozen_string_literal: true

require "json"
require "fileutils"

# Writes the JSON files that the release pages fetch at runtime, built from each version's _data YAML.
# Pages render one record at a time instead of inlining every record as hidden HTML.
#
# Output per version, under _site/releases/<version>/: <type>_data/<shard>.json, detail records for the values,
# return reasons and disclosures pages keyed by handle (or public id), split into SHARD_COUNT files.
module ReleaseData
  # Must match SHARD_COUNT and shardFor() in docs/assets/js/release_data.js.
  SHARD_COUNT = 256

  class << self
    def write(site)
      markdown = site.find_converter_instance(Jekyll::Converters::Markdown)

      site.data.each do |version, data|
        next unless data.is_a?(Hash) && data["attributes"].is_a?(Array)

        target_dir = File.join(site.dest, "releases", version)
        FileUtils.mkdir_p(target_dir)

        if (values = data.dig("reversed_values", "values"))
          write_values(target_dir, values)
        end
        if (return_reasons = data.dig("reversed_return_reasons", "return_reasons"))
          write_return_reasons(target_dir, return_reasons)
        end
        if (disclosures = data["disclosures"])
          write_disclosures(target_dir, disclosures, markdown)
        end
      end
    end

    # FNV-1a (32-bit) over the UTF-8 bytes of the key, formatted as two hex digits.
    def shard_for(key)
      hash = 0x811c9dc5
      key.to_s.each_byte { |byte| hash = ((hash ^ byte) * 0x01000193) & 0xffffffff }
      format("%02x", hash % SHARD_COUNT)
    end

    private

    def write_values(target_dir, values)
      records = values.map do |value|
        attribute = value["attribute"]
        {
          "id" => value["id"],
          "handle" => value["handle"],
          "name" => value["name"],
          "attribute" => attribute && { "handle" => attribute["handle"], "name" => attribute["name"] },
        }
      end
      write_shards(File.join(target_dir, "value_data"), records.map { |record| [record["handle"], record] })
    end

    def write_return_reasons(target_dir, return_reasons)
      records = return_reasons.map do |return_reason|
        {
          "id" => return_reason["id"],
          "handle" => return_reason["handle"],
          "name" => return_reason["name"],
          "description" => return_reason["description"],
          "categories" => (return_reason["categories"] || []).map { |category| category["full_name"] },
        }
      end
      write_shards(File.join(target_dir, "return_reason_data"), records.map { |record| [record["handle"], record] })
    end

    def write_disclosures(target_dir, disclosures, markdown)
      records = disclosures.map do |disclosure|
        record = disclosure.slice(
          "id",
          "public_id",
          "name",
          "description",
          "parent_public_id",
          "jurisdictions",
          "legal_citation",
          "symbol",
          "display_requirements",
          "source",
          "title",
          "children",
        )
        # Pre-render Markdown so the page shows the same HTML as the `markdownify` filter did.
        record["content_html"] = disclosure["content"] && markdown.convert(disclosure["content"].to_s)
        record
      end
      write_shards(File.join(target_dir, "disclosure_data"), records.map { |record| [record["public_id"], record] })
    end

    # Writes all SHARD_COUNT shard files, mapping key -> record; empty shards are `{}` so the page
    # can treat any failed request as an error. `entries` are [key, record] pairs.
    def write_shards(dir, entries)
      FileUtils.rm_rf(dir)
      FileUtils.mkdir_p(dir)
      duplicates = entries.map(&:first).tally.select { |_, count| count > 1 }.keys
      Jekyll.logger.warn("ReleaseData:", "duplicate keys in #{dir}, first one wins: #{duplicates.first(5).join(", ")}") if duplicates.any?

      shards = Array.new(SHARD_COUNT) { |index| [format("%02x", index), {}] }.to_h
      entries.each { |key, record| shards[shard_for(key)][key.to_s] ||= record }
      shards.each { |shard, records| write_json(File.join(dir, "#{shard}.json"), records) }
    end

    def write_json(path, payload)
      File.write(path, JSON.generate(payload))
    end
  end
end

Jekyll::Hooks.register(:site, :post_write) do |site|
  ReleaseData.write(site)
end
