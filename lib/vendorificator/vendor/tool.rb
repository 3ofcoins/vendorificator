require 'fileutils'
require 'tempfile'

require 'vendorificator/vendor'

module Vendorificator
  class Vendor::Tool < Vendor
    arg_reader :specs, :command

    def before_conjure!
      upstream_version # to cache the version in instance attribute,
                       # it will be needed when we don't have the
                       # specs
    end

    def conjure!
      specs.each do |spec|
        src = File.join(environment.git.git_work_tree, spec)
        if File.exist?(src)
          FileUtils.install File.join(environment.git.git_work_tree, spec),
                            File.join(git.git_work_tree, spec)
        end
        Dir.chdir(git.git_work_tree) do
          system self.command or raise RuntimeError, "Command failed"
        end
      end
    end

    def git_add_extra_paths
      specs.inject(super) do |rv, path|
        rv << path
      end
    end

    def upstream_version
      @upstream_version ||= git.capturing.
        log({:n => 1, :pretty => 'format:%ad-%h', :date => 'short'}, *specs).
        strip
    end
  end

  class Config
    register_module :tool, Vendor::Tool

    def rubygems_bundler
      tool 'rubygems',
           :path => 'cache', # Hardcoded, meh
           :specs => [ 'Gemfile', 'Gemfile.lock' ],
           :command => 'bundle package --all > /dev/null'
    end

    def chef_berkshelf
      tool 'cookbooks',
           :path => 'cookbooks',
           :specs => [ 'Berksfile', 'Berksfile.lock' ],
           :command => 'berks install --quiet --path vendor/cookbooks'
    end
  end
end
