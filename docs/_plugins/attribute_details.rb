# frozen_string_literal: true

require "json"

module AttributeDetailsShards
  def self.shard(handle)
    handle.bytes.reduce(2_166_136_261) do |hash, byte|
      ((hash ^ byte) * 16_777_619) & 0xffff_ffff
    end % 256
  end

  def self.write(version_data, target_dir)
    category_values = version_data.fetch("attributes").to_h do |attribute|
      [attribute.fetch("handle"), attribute.fetch("values")]
    end
    shards = Hash.new { |hash, key| hash[key] = {} }

    version_data.fetch("reversed_attributes").fetch("attributes").each do |attribute|
      handle = attribute.fetch("handle")
      shards[shard(handle)][handle] = {
        "category_values" => category_values.fetch(handle),
        "values" => attribute.fetch("values"),
        "categories" => attribute.fetch("categories"),
      }
    end

    FileUtils.mkdir_p(target_dir)
    shards.each do |shard, attributes|
      File.write(File.join(target_dir, format("attribute_details_%02x.json", shard)), JSON.generate(attributes))
    end
  end
end

Jekyll::Hooks.register(:site, :post_write) do |site|
  site.data.each do |version, version_data|
    next unless version_data.is_a?(Hash) && version_data.key?("reversed_attributes") && version_data.key?("attributes")

    AttributeDetailsShards.write(version_data, File.join(site.dest, "releases", version))
  end
end
