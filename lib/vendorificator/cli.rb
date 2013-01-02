require 'thor'

require 'vendorificator'

module Vendorificator
  class CLI < Thor
    include Vendorificator

    check_unknown_options!
    default_task :sync

    class_option :file, :aliases => '-f', :type => :string, :banner => 'PATH'

    def initialize(*args)
      super
      Vendorificator::Config.from_file(find_vendorfile)
      Vendorificator::Config[:shell] = shell

      # Ensure we're in a Git repository and it's clean
      begin
        # copy code from http://stackoverflow.com/a/3879077/16390
        Vendorificator::Config.repo.git.native :update_index, {}, '-q', '--ignore-submodules', '--refresh'
        Vendorificator::Config.repo.git.native :diff_files, {:raise => true}, '--quiet', '--ignore-submodules', '--'
        Vendorificator::Config.repo.git.native :diff_index, {:raise => true}, '--cached', '--quiet', 'HEAD', '--ignore-submodules', '--'
      rescue Grit::Git::CommandFailed
        raise RuntimeError, "Git repository is not clean."
      end

    end

    desc :sync, "Download new or updated vendor files"
    def sync
      # We don't use Vendorificator::Config[:modules].each here,
      # because mod.run! is explicitly allowed to append to
      # Vendorificator::Config[:modules], and #each fails to catch up
      # on some Ruby implementations.
      i = 0
      while true
        break if i >= Vendorificator::Config[:modules].length
        mod = Vendorificator::Config[:modules][i]
        say_status :module, mod.name
        begin
          shell.padding += 1
          mod.run!
        ensure
          shell.padding -= 1
        end
        i += 1
      end
    end

    def self.start
      if ENV['FIXTURES_DIR']
        require 'vcr'
        VCR.configure do |c|
          c.cassette_library_dir = File.join(ENV['FIXTURES_DIR'], 'vcr_cassettes')
          c.default_cassette_options = { :record => :new_episodes }
          c.hook_into :fakeweb
        end
        VCR.use_cassette(ENV['VCR_CASSETTE'] || 'vendorificator') do
          super
        end
      else
        super
      end
    end

    private

    # Find proper Vendorfile
    def find_vendorfile
      given = options.file || ENV['VENDORFILE']
      return Pathname.new(given).expand_path if given && !given.empty?

      Pathname.pwd.ascend do |dir|
        vf = dir.join('Vendorfile')
        return vf if vf.exist?

        vf = dir.join('config/vendor.rb')
        return vf if vf.exist?

        # avoid stepping above the tmp directory when testing
        if ENV['VENDORIFICATOR_SPEC_RUN'] &&
            dir.join('vendorificator.gemspec').exist?
          raise RuntimeError, "Vendorfile not found"
        end
      end

      raise RuntimeError, "Vendorfile not found"
    end

  end
end
