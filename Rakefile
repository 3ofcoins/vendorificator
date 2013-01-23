#!/usr/bin/env rake
require "rubygems"
require "bundler"
Bundler.setup

require "bundler/gem_tasks"

namespace :relish do
  desc "Publish documentation to Relish"
  task :push do
    sh "relish push 3ofcoins/vendorificator"
  end
end

begin
  require 'cucumber'
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "--format pretty --verbose"
  end
rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end

task :default => :features
