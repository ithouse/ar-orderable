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
  gem.name = "ar-orderable"
  gem.homepage = "http://github.com/ithouse/ar-orderable"
  gem.license = "MIT"
  gem.summary = %Q{Rails 3 plugin for simple ordering.}
  gem.description = %Q{You can order AR records and skip callbacks}
  gem.email = "gatis@ithouse.cc"
  gem.authors = ["Gatis Tomsons","IT House"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'spec'
  test.pattern = 'spec/**/_spec*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ar-orderable #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
