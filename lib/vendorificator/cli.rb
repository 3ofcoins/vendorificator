require 'thor'

require 'vendorificator'

module Vendorificator
  class CLI < Thor
    include Vendorificator

    check_unknown_options!
    default_task :sync

    class_option :file, :aliases => '-f', :type => :string, :banner => 'PATH'
    class_option :debug, :aliases => '-d', :type => :boolean, :default => false

    MODULES_USAGE     = '[module [module [module ...]]]'
    MODULES_DESC      = 'If no modules are given, all modules will be used.'
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

    desc "status #{MODULES_USAGE}", "List known vendor modules and their status"
    long_desc <<EOF
Lists known vendor modules and their status.
#{MODULES_DESC}
EOF
    def status(*modules)
      say_status 'WARNING', 'Git repository is not clean', :red unless repo.clean?
      Vendorificator::Config.each_module(*modules) do |mod|
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

    desc :pull, "Pull upstream branches from a remote repository"
    method_option :remote, :aliases => ['-r'], :default => nil
    method_option :dry_run, :aliases => ['-n'], :default => false, :type => :boolean
    def pull
      ensure_clean_repo!
      remotes = options[:remote] ? options[:remote].split(',') : conf[:remotes]
      remotes.each do |remote|
        indent 'remote', remote do
          repo.pull(remote, options)
        end
      end
    end

    desc :pry, 'Pry into the binding', :hide => true
    def pry
      require 'pry'
      binding.pry
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

    def conf
      Vendorificator::Config
    end

    def repo
      Vendorificator::Config.repo
    end

    def fail!(message, exception_message='I give up.')
      say_status('FATAL', message, :red)
      raise Thor::Error, 'I give up.'
    end

    def indent(*args, &block)
      say_status *args unless args.empty?
      shell.padding += 1
      yield
    ensure
      shell.padding -= 1
    end

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

    def ensure_clean_repo!
      unless repo.clean?
        fail!('Repository is not clean.')
      end
    end
  end
end
