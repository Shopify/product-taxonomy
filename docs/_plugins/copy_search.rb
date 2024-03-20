# frozen_string_literal: true

# this doesn't run on GitHub Pages, hence the bin command
root = File.expand_path("../..", __dir__)
Jekyll::Hooks.register(:site, :post_write) do
  system("#{root}/bin/copy_docs_search_indexes")
end
