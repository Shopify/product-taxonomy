# -*- encoding: utf-8 -*-
# stub: minitest-silence 0.2.4 ruby lib

Gem::Specification.new do |s|
  s.name = "minitest-silence".freeze
  s.version = "0.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "homepage_uri" => "https://github.com/Shopify/minitest-silence", "source_code_uri" => "https://github.com/Shopify/minitest-silence" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Willem van Bergen".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-02-17"
  s.description = "Minitest plugin to suppress output from tests. This plugin will buffer any output coming from\na test going to STDOUT or STDERR, to make sure it doesn't interfere with the output of the test\nrunner itself. By default, it will discard any output, unless the `--verbose` option is set\nIt also supports failing a test if it is writing anything to STDOUT or STDERR by setting the\n`--fail-on-output` command line option.\n".freeze
  s.email = ["willem@vanbergen.org".freeze]
  s.homepage = "https://github.com/Shopify/minitest-silence".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Minitest plugin to suppress output from tests.".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<minitest>.freeze, ["~> 5.12"])
end
