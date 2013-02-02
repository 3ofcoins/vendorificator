require 'thor'

require 'vendorificator'

module Vendorificator
  class CLI < Thor
    include Vendorificator

    check_unknown_options! :except => [:git, :diff, :log]
    stop_on_unknown_option! :git, :diff, :log

    default_task :help

    class_option :file, :aliases => '-f', :type => :string, :banner => 'PATH'
    class_option :debug, :aliases => '-d', :type => :boolean, :default => false
    class_option :quiet, :aliases => ['-q'], :default => false, :type => :boolean
    class_option :modules, :type => :string, :default => '',
      :banner => 'mod1,mod2,...,modN',
      :desc => 'Run only for specified modules (name or path, comma separated)'

    def initialize(*args)
      super
      Grit.debug = true if options[:debug]
      Vendorificator::Config.from_file(find_vendorfile)
      Vendorificator::Config[:shell] = shell

      class << shell
        # Make say_status always say it.
        def quiet?
          false
        end
      end
    end

    desc :sync, "Download new or updated vendor files"
    def sync
      ensure_clean_repo!
      Vendorificator::Config.each_module(*modules) do |mod|
        say_status :module, mod.name
        begin
          shell.padding += 1
          mod.run!
        ensure
          shell.padding -= 1
        end
      end
    end

    desc "status", "List known vendor modules and their status"
    def status
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
    desc "git GIT_COMMAND [GIT_ARGS [...]]",
         "Run a git command for specified modules"
    long_desc <<EOF
  Run a git command for specified modules. Within GIT_ARGS arguments,
  you can use @MERGED@ and @PATH@ tags, which will be substituted with
  mo#dule's most recently merged revision and full path of its work
  directory.

  The 'diff' and 'log' commands are simple aliases for 'git' command.

  Examples:
    vendor git log @MERGED@..HEAD -- @PATH@    # basic 'vendor log'
    vendor git diff --stat @MERGED@ -- @PATH@  # 'vendor diff', as diffstat
EOF
    method_option :only_changed, :default => false, :type => :boolean
    def git(command, *args)
      Vendorificator::Config.each_module(*modules) do |mod|
        unless mod.merged
          say_status 'unmerged', mod.to_s, :red unless options[:only_changed]
          next
        end

        actual_args = args.dup.map do |arg|
          arg.
            gsub('@MERGED@', mod.merged).
            gsub('@PATH@', mod.work_dir)
        end

        output = repo.git.native(command, {}, *actual_args)
        if output.empty?
          say_status 'unchanged', mod.to_s, :green unless options[:only_changed]
        else
          say_status 'changed', mod.to_s, :yellow
        end
        puts output unless options[:quiet] || output.empty?
      end
    end

    desc "diff [OPTIONS] [GIT OPTIONS]",
         "Show differences between work tree and upstream module(s)"
    method_option :only_changed, :default => false, :type => :boolean
    def diff(*args)
      invoke :git, %w'diff' + args + %w'@MERGED@ -- @PATH@'
    end

    desc "log [OPTIONS] [GIT OPTIONS]",
         "Show git log of commits added to upstream module(s)"
    method_option :only_changed, :default => false, :type => :boolean
    def log(*args)
      invoke :git, %w'log' + args + %w'@MERGED@..HEAD -- @PATH@'
    end

    desc :pry, 'Pry into the binding', :hide => true
    def pry
      require 'pry'
      binding.pry
    end

    def self.start
      # Make --git-options always quoted
      if i = ARGV.index('--git-options')
        ARGV[i+1,0] = '--'
      end

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

    def split_git_options(args)
      case i = args.index('--git-options')
      when nil then [ args, [] ]
      when 0 then [ [], args[1..-1] ]
      else [ args[0..(i-1)], args[(i+1)..-1] ]
      end
    end

    def modules
      options[:modules].split(',').map(&:strip)
    end

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

# Monkey patch over https://github.com/wycats/thor/pull/298
class Thor::Options
  alias_method :_orig_current_is_switch?, :current_is_switch?
  def current_is_switch?
    rv = _orig_current_is_switch?
    @parsing_options = false if !rv[0] && @stop_on_unknown && @parsing_options
    rv
  end
end
