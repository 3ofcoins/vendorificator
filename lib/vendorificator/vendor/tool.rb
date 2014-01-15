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
      Dir.chdir(git.git_work_tree) do
        git.checkout(environment.current_branch, '--', spec_files) unless spec_files.empty?
        system self.command or raise RuntimeError, "Command failed"
        super
      end
    end

    def upstream_version
      @upstream_version ||= git.capturing.
        log({:n => 1, :pretty => 'format:%ad-%h', :date => 'short'}, spec_files).
        strip
    end

    private

    def spec_files
      @spec_files ||=
        begin
          _specs = Array(specs)
          git.capturing.
            ls_tree({:r => true, :z => true, :name_only => true}, environment.current_branch).
            split("\0").
            select do |path|
              _specs.any? do |spec|
                File.fnmatch(spec, path, File::FNM_PATHNAME)
              end
            end
        end
    end
  end

  class Config
    register_module :tool, Vendor::Tool

    def rubygems_bundler(&block)
      tool 'rubygems',
           :path => 'cache', # Hardcoded, meh
           :specs => [ 'Gemfile', 'Gemfile.lock' ],
           :command => 'bundle package --all',
           &block
    end

    def chef_berkshelf(args={}, &block)
      args[:path] ||= 'cookbooks'
      args[:specs] ||= []
      args[:specs] |= [ 'Berksfile', 'Berksfile.lock' ]
      args[:command] = "berks install --path vendor/#{args[:path]}"
      tool 'cookbooks', args, &block
    end
  end
end
