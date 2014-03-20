$:.unshift File.expand_path('../lib', __FILE__)
require 'git-version-bump'

Gem::Specification.new do |s|
	s.name = "marquise"

	s.version = GVB.version
	s.date    = GVB.date

	s.platform = Gem::Platform::RUBY

	s.homepage = "https://github.com/mpalmer/marquise-ruby"
	s.summary = "Ruby bindings for the marquise data-point transport "+
	            "for Vaultaire"
	s.authors = ["Matt Palmer"]

	s.extra_rdoc_files = ["README.md"]
	s.files = `git ls-files`.split("\n")

	s.add_runtime_dependency 'ffi', '~> 1.9'
	s.add_runtime_dependency 'git-version-bump', '~> 0.7'

	s.add_development_dependency 'rspec', "~> 2.14"
	s.add_development_dependency 'rake'
	s.add_development_dependency 'bundler'
	s.add_development_dependency 'rdoc'
	s.add_development_dependency 'guard-spork'
	s.add_development_dependency 'guard-rspec'
	s.add_development_dependency 'rb-inotify', '~> 0.9'
end
