# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "metarepo"
  gem.homepage = "http://github.com/adamhjk/metarepo"
  gem.license = "MIT"
  gem.summary = %Q{Creates and tracks repositories for many operating systems}
  gem.description = %Q{Takes pacakges, builds repos}
  gem.email = "adam@opscode.com"
  gem.authors = ["Adam Jacob"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

desc "Execute a pry session with the paths preloaded"
task :pry do
  exec "pry -I #{File.join(File.dirname(__FILE__), "lib")} -r metarepo"
end

task :default => :spec


require 'yard'
YARD::Rake::YardocTask.new

require 'resque/tasks'

task "resque:setup" do
  $: << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  require 'metarepo'
  if File.exists?("/etc/metarepo.rb")
    Metarepo::Config.from_file("/etc/metarepo.rb")
  end
  Metarepo::Log.level = :debug
  Metarepo.connect_db 
  require 'metarepo/job/repo_sync_packages'
  require 'metarepo/job/upstream_sync_packages'
  require 'metarepo/job/repo_packages'
end

