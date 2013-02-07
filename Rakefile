#!/usr/bin/env rake
require "rubygems"
require "bundler"
Bundler.setup

require "bundler/gem_tasks"
require 'rake/testtask'

namespace :relish do
  desc "Publish documentation to Relish"
  task :push do
    sh "relish push 3ofcoins/vendorificator"
  end
end

begin
  require 'cucumber'
  require 'cucumber/rake/task'

  desc 'Run Cucumber features'
  Cucumber::Rake::Task.new(:features)
rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end

task :bundle do
  sh 'bundle list'
end

desc "Run Minitest specs"
Rake::TestTask.new :spec do |task|
  task.libs << 'spec'
  task.test_files = FileList['spec/**/*_spec.rb']
end

task :default => [:bundle, :spec, :features]
