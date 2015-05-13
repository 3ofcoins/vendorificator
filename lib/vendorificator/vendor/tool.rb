require 'fileutils'
require 'tempfile'

require 'vendorificator/vendor'

module Vendorificator
  class Vendor::Tool < Vendor
    arg_reader :specs, :extras, :command

    def before_conjure!
      upstream_version # to cache the version in instance attribute,
                       # it will be needed when we don't have the
                       # specs
    end

    def conjure!
      Dir.chdir(git.git_work_tree) do
        git.checkout(
          "origin/#{environment.current_branch}", '--', specs_in_repo, extras_in_repo
          ) unless specs_in_repo.empty? && extras_in_repo.empty?
        git.rm({:cached => true}, extras_in_repo) unless extras_in_repo.empty?
        system self.command or raise RuntimeError, "Command failed"
        super
      end
    end

    def upstream_version
      @upstream_version ||= git.capturing.
        log({:n => 1, :pretty => 'format:%ad-%h', :date => 'short'}, specs_in_repo).
        strip
    end

    private

    def specs_in_repo
      @spec_in_repo ||= select_by_glob_list(origin_files, specs)
    end

    def extras_in_repo
      @extras_in_repo ||= select_by_glob_list(origin_files, extras)
    end

    def select_by_glob_list(haystack, needles)
      return [] if !needles || needles.empty?
      needles = Array(needles)
      haystack.select do |straw|
        needles.any? do |needle|
          File.fnmatch(needle, straw, File::FNM_PATHNAME)
        end
      end
    end

    def origin_files
      @origin_files ||= git.capturing.
        ls_tree( {:r => true, :z => true, :name_only => true},
                 environment.current_branch).
        split("\0")
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
      if args[:berks2]
        args[:command] = "berks install --path vendor/#{args[:path]}"
      else
        args[:command] = "berks vendor vendor/#{args[:path]}"
      end
      tool 'cookbooks', args do |v|
        # Unignore metadata.json files
        Dir["vendor/#{args[:path]}/*/.gitignore"].each do |gitignore_path|
          ignored = File.read(gitignore_path)
          ignored_proper = ignored
            .lines
            .reject { |ln| ln =~ /^\s*\/?metadata\.json/ }
            .join
          File.write(gitignore_path, ignored_proper) if ignored_proper != ignored
        end
        block.call(v) if block
      end
    end
  end
end
