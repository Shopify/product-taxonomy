# frozen_string_literal: true

root = File.expand_path("../..", __dir__)

Jekyll::Hooks.register(:site, :post_write) do
  Dir.glob("#{root}/docs/_data/*/").each do |dir|
    src = "#{dir}search_index.json"
    target = "#{root}/_site/releases/#{File.basename(dir)}/search_index.json"
    puts "Copying #{src} to #{target}"
    FileUtils.cp(src, target)
  end
end
