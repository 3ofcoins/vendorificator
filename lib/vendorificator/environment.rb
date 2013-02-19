require 'pathname'

require 'minigit'

require 'vendorificator/config'

module Vendorificator
  class Environment
    attr_reader :config
    attr_accessor :shell

    def initialize(vendorfile=nil)
      @config = Vendorificator::Config
      config.from_file(self.class.find_vendorfile(vendorfile))
    end

    def git
      @git ||= MiniGit::new(config[:vendorfile])
    end

    def clean?
      # copy code from http://stackoverflow.com/a/3879077/16390
      git.update_index :q => true, :ignore_submodules => true, :refresh => true
      git.diff_files '--quiet', '--ignore-submodules', '--'
      git.diff_index '--cached', '--quiet', 'HEAD', '--ignore-submodules', '--'
      true
    rescue MiniGit::GitError
      false
    end

    def self.find_vendorfile(given=nil)
      given = [ given, ENV['VENDORFILE'] ].find do |candidate|
        candidate && !(candidate.respond_to?(:empty?) && candidate.empty?)
      end
      return given if given

      Pathname.pwd.ascend do |dir|
        vf = dir.join('Vendorfile')
        return vf if vf.exist?

        vf = dir.join('config/vendor.rb')
        return vf if vf.exist?

        # avoid stepping above the tmp directory when testing
        if ENV['VENDORIFICATOR_SPEC_RUN'] &&
            dir.join('vendorificator.gemspec').exist?
          raise ArgumentError, "Vendorfile not found"
        end
      end

      raise ArgumentError, "Vendorfile not found"
    end
  end
end
