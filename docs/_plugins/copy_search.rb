# frozen_string_literal: true

Jekyll::Hooks.register(:site, :post_write) do |site|
  source_data_dir = File.join(site.source, "_data")
  site_dest = site.dest

  Dir.glob(File.join(source_data_dir, "*")).each do |version_dir|
    next unless File.directory?(version_dir)

    version = File.basename(version_dir)
    target_dir = File.join(site_dest, "releases", version)
    Dir.mkdir(target_dir) unless Dir.exist?(target_dir)

    ["search_index.json", "attribute_search_index.json"].each do |file|
      source_file = File.join(version_dir, file)
      target_file = File.join(target_dir, file)

      FileUtils.cp(source_file, target_file) if File.exist?(source_file)
    end
  end
end
