# -*- encoding: utf-8 -*-
# stub: minitest-hooks 1.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "minitest-hooks".freeze
  s.version = "1.5.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jeremy Evans".freeze]
  s.date = "2024-08-14"
  s.description = "minitest-hooks adds around and before_all/after_all/around_all hooks for Minitest.\nThis allows you do things like run each suite of specs inside a database transaction,\nrunning each spec inside its own savepoint inside that transaction, which can\nsignificantly speed up testing for specs that share expensive database setup code.\n".freeze
  s.email = "code@jeremyevans.net".freeze
  s.extra_rdoc_files = ["README.rdoc".freeze, "CHANGELOG".freeze, "MIT-LICENSE".freeze]
  s.files = ["CHANGELOG".freeze, "MIT-LICENSE".freeze, "README.rdoc".freeze]
  s.homepage = "http://github.com/jeremyevans/minitest-hooks".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--quiet".freeze, "--line-numbers".freeze, "--inline-source".freeze, "--title".freeze, "minitest-hooks: around and before_all/after_all/around_all hooks for Minitest".freeze, "--main".freeze, "README.rdoc".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Around and before_all/after_all/around_all hooks for Minitest".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<minitest>.freeze, ["> 5.3"])
  s.add_development_dependency(%q<sequel>.freeze, ["> 4"])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest-global_expectations>.freeze, [">= 0"])
end
