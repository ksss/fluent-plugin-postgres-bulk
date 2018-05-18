require "bundler/gem_tasks"
require 'fileutils'
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true

  if ENV["WITH_DOCKER"]
    file "test/plugin/docker/plugins/out_postgres_bulk.rb" => "lib/fluent/plugin/out_postgres_bulk.rb"
    FileUtils.cp "lib/fluent/plugin/out_postgres_bulk.rb", "test/plugin/docker/plugins/out_postgres_bulk.rb"
  end
end

task :default => :test
