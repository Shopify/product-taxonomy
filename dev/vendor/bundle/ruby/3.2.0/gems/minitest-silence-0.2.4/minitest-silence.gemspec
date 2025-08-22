# frozen_string_literal: true
require_relative 'lib/minitest/silence/version'

Gem::Specification.new do |spec|
  spec.name          = "minitest-silence"
  spec.version       = Minitest::Silence::VERSION
  spec.authors       = ["Willem van Bergen"]
  spec.email         = ["willem@vanbergen.org"]

  spec.summary       = 'Minitest plugin to suppress output from tests.'
  spec.description   = <<~DESCRIPTION
    Minitest plugin to suppress output from tests. This plugin will buffer any output coming from
    a test going to STDOUT or STDERR, to make sure it doesn't interfere with the output of the test
    runner itself. By default, it will discard any output, unless the `--verbose` option is set
    It also supports failing a test if it is writing anything to STDOUT or STDERR by setting the
    `--fail-on-output` command line option.
  DESCRIPTION
  spec.homepage      = "https://github.com/Shopify/minitest-silence"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Shopify/minitest-silence"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("minitest", "~> 5.12")
end
