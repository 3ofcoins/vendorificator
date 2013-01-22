require 'pathname'

require 'grit'
require 'mixlib/config'

module Vendorificator
  class Config
    extend Mixlib::Config

    configure do |c|
      c[:root] = Pathname.getwd
      c[:basedir] = 'vendor'
      c[:branch_prefix] = 'vendor/'
      c[:modules] = []
      c[:remotes] = %w(origin)
    end

    def self.from_file(filename)
      pathname = Pathname.new(filename).cleanpath.expand_path
      self[:root_dir] =
        if ( pathname.basename.to_s == 'vendor.rb' &&
               pathname.dirname.basename.to_s == 'config' )
          # Correctly recognize root dir if main config is 'config/vendor.rb'
          pathname.dirname.dirname
        else
          pathname.dirname
        end
      self[:vendorfile_path] = pathname
      self[:lockfile_path] = pathname.dirname.join(pathname.basename.to_s + '.lock')
      super(pathname.to_s)
    end

    def self.repo
      @repo ||= begin
                  git_root_path = self[:repo_dir] || _find_git_root
                  raise "Can't find Git repository" unless git_root_path
                  Grit::Repo.new( git_root_path.to_s )
                end
    end

    def self.each_module
      # We don't use self[:modules].each here, because mod.run! is
      # explicitly allowed to append to Config[:modules], and #each
      # fails to catch up on some Ruby implementations.
      i = 0
      while true
        break if i >= Vendorificator::Config[:modules].length
        mod = Vendorificator::Config[:modules][i]
        yield mod
        i += 1

        # Add dependencies
        work_dirs = Vendorificator::Config[:modules].map(&:work_dir)
        Vendorificator::Config[:modules] +=
          mod.dependencies.reject { |dep| work_dirs.include?(dep.work_dir) }
      end
    end

    def self._find_git_root
      self[:root_dir].ascend do |dir|
        return dir if dir.join('.git').exist?
      end
    end
    private_class_method :_find_git_root
  end
end
