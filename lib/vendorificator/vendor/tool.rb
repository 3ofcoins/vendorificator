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
      @contents = Tempfile.new(["vendorificator-tool-#{name}", ".tar"])
      @contents.close
      system self.command or raise RuntimeError, "Command failed"
      Dir.chdir(config[:root_dir]) do
        system 'tar', '-cf', @contents.path, work_subdir, *specs
        # Restore work subdir so that we have a clean sla
        git.clean({:f => true, :d => true, :x => true}, work_subdir)
      end
    end

    def conjure!
      Dir.chdir(config[:root_dir]) do
        system 'tar', '-xf', @contents.path
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
  end
end
