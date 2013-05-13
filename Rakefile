#!/usr/bin/env rake
require "rubygems"
require "bundler"
Bundler.setup

require "bundler/gem_tasks"
require 'rake/testtask'

begin
  require 'berkshelf/version'
rescue LoadError
end

namespace :relish do
  desc "Publish documentation to Relish"
  task :push do
    sh "relish push 3ofcoins/vendorificator"
  end
end

task :info do
  sh 'which git'
  sh 'git --version'
end

begin
  require 'cucumber'
  require 'cucumber/rake/task'

  desc 'Run Cucumber features'
  Cucumber::Rake::Task.new(:features) do |t|
    t.fork = false
    t.cucumber_opts = %w{--format progress}
    t.cucumber_opts += %w{--tags ~@berkshelf} unless defined?(Berkshelf)
  end
rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end

desc "Run Minitest specs"
Rake::TestTask.new :spec do |task|
  task.libs << 'spec'
  task.test_files = FileList['spec/**/*_spec.rb']
end

# https://github.com/jruby/jruby/issues/405
mkdir_p 'tmp'
ENV['TMPDIR'] ||= File.join(Dir.pwd, 'tmp')

task :default => [:info, :spec, :features]

if ENV['COVERAGE']
  task :clean_coverage do
    rm_rf 'coverage'
  end

  task :spec => :clean_coverage
  task :features => :clean_coverage
end
