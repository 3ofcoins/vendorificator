require 'thor'

require 'vendorificator'

module Vendorificator
  class CLI < Thor
    include Vendorificator

    check_unknown_options!
    default_task :sync

    class_option :file, :aliases => '-f', :type => :string, :banner => 'PATH'
    class_option :debug, :aliases => '-d', :type => :boolean, :default => false

    def initialize(*args)
      super
      Grit.debug = true if options[:debug]
      Vendorificator::Config.from_file(find_vendorfile)
      Vendorificator::Config[:shell] = shell
    end

    desc :sync, "Download new or updated vendor files"
    def sync
      ensure_clean_repo!
      Vendorificator::Config.each_module do |mod|
        say_status :module, mod.name
        begin
          shell.padding += 1
          mod.run!
        ensure
          shell.padding -= 1
        end
      end
    end

    desc :status, "List known vendor modules and their status"
    def status
      say_status 'WARNING', 'Git repository is not clean', :red unless clean_repo?
      Vendorificator::Config.each_module do |mod|
        status_line = mod.to_s

        updatable = mod.updatable?
        if updatable
          if updatable == true
            status_line << ' (updatable)'
          else
            status_line << " (updatable to #{updatable.name})"
          end
        end

        say_status( mod.status.to_s.gsub('_', ' '), status_line,
                    ( mod.status==:up_to_date ? :green : :yellow ) )
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

    def clean_repo?
      # copy code from http://stackoverflow.com/a/3879077/16390
      Vendorificator::Config.repo.git.native :update_index, {}, '-q', '--ignore-submodules', '--refresh'
      Vendorificator::Config.repo.git.native :diff_files, {:raise => true}, '--quiet', '--ignore-submodules', '--'
      Vendorificator::Config.repo.git.native :diff_index, {:raise => true}, '--cached', '--quiet', 'HEAD', '--ignore-submodules', '--'
      true
    rescue Grit::Git::CommandFailed
      false
    end

    def ensure_clean_repo!
      unless clean_repo?
        fail!('Repository is not clean.')
      end
    end
  end
end
