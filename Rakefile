require 'rubygems'
require 'bundler'

task :default => :test

begin
	Bundler.setup
rescue Bundler::BundlerError => e
	$stderr.puts e.message
	$stderr.puts "Run `bundle install` to install missing gems"
	exit e.status_code
end

Bundler::GemHelper.install_tasks

require 'rdoc/task'

Rake::RDocTask.new do |rd|
	rd.main = "README.md"
	rd.title = 'marquise'
	rd.rdoc_files.include("README.md", "lib/**/*.rb")
end

require 'git-version-bump/rake-tasks'

desc "Run guard"
task :guard do
	Bundler.setup(:default, :test)
	require 'guard'
	::Guard.start(:clear => true)
	while ::Guard.running do
		sleep 0.5
	end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new :test do |t|
	t.pattern = "spec/**/*_spec.rb"
end
