if ENV['COVERAGE']
  require 'pathname'
  require 'simplecov'
  SimpleCov.start do
    add_group 'Vendors', 'lib/vendorificator/vendor'
    root Pathname.new(__FILE__).dirname.dirname.dirname.realpath.to_s
    use_merging
  end
  SimpleCov.command_name "vendor##{$$}@#{DateTime.now.to_s}"
end

require 'thor'
require 'vendorificator'

module Vendorificator
  class CLI < Thor
    attr_reader :environment

    check_unknown_options! :except => [:git, :diff, :log]
    stop_on_unknown_option! :git, :diff, :log

    default_task :help

    class_option :file,    :aliases => '-f', :type => :string,
      :banner => 'PATH'
    class_option :debug,   :aliases => '-d', :type => :boolean, :default => false
    class_option :quiet,   :aliases => '-q', :type => :boolean, :default => false
    class_option :modules, :aliases => '-m', :type => :string,  :default => '',
      :banner => 'mod1,mod2,...,modN',
      :desc => 'Run only for specified modules (name or path, comma separated)'
    class_option :version,                   :type => :boolean
    class_option :help,    :aliases => '-h', :type => :boolean

    def initialize(args=[], options={}, config={})
      super

      if self.options[:version]
        say "Vendorificator #{Vendorificator::VERSION}"
        exit
      end

      if self.options[:help] && config[:current_task].name != 'help'
        invoke :help, [ config[:current_task].name ]
        exit
      end

      @environment = Vendorificator::Environment.new(self.options[:file])
      environment.shell = shell

      class << shell
        # Make say_status always say it.
        def quiet?
          false
        end
      end
    end

    desc :sync, "Download new or updated vendor files"
    method_option :update, :type => :boolean, :default => false
    def sync
      environment.sync options.merge(:modules => modules)
    rescue DirtyRepoError
      fail! 'Repository is not clean.'
    end

    desc "status", "List known vendor modules and their status"
    method_option :update, :type => :boolean, :default => false
    def status
      say_status 'WARNING', 'Git repository is not clean', :red unless environment.clean?
      environment.config[:use_upstream_version] = options[:update]
      environment.each_vendor_instance(*modules) do |mod|
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
      environment.pull_all options
    rescue DirtyRepoError
      fail! 'Repository is not clean.'
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
    def git(command, *args)
      environment.each_vendor_instance(*modules) do |mod|
        unless mod.merged
          say_status 'unmerged', mod.to_s, :red unless options[:only_changed]
          next
        end

        actual_args = args.dup.map do |arg|
          arg.
            gsub('@MERGED@', mod.merged).
            gsub('@PATH@', mod.work_dir)
        end

        say_status command, mod.to_s
        output = environment.git.git(command, *actual_args)
      end
    end

    desc "diff [OPTIONS] [GIT OPTIONS]",
         "Show differences between work tree and upstream module(s)"
    def diff(*args)
      invoke :git, %w'diff' + args + %w'@MERGED@ -- @PATH@'
    end

    desc "log [OPTIONS] [GIT OPTIONS]",
         "Show git log of commits added to upstream module(s)"
    def log(*args)
      invoke :git, %w'log' + args + %w'@MERGED@..HEAD -- @PATH@'
    end

    desc :pry, 'Pry into the binding', :hide => true
    def pry
      require 'pry'
      binding.pry
    end

    def self.start(*args)
      # Make --git-options always quoted
      if i = ARGV.index('--git-options')
        ARGV[i+1,0] = '--'
      end

      if ENV['FIXTURES_DIR']
        require 'vcr'
        VCR.configure do |c|
          c.cassette_library_dir = File.join(ENV['FIXTURES_DIR'], 'vcr')
          c.default_cassette_options = { :record => :new_episodes }
          c.hook_into :webmock
        end
        VCR.use_cassette(ENV['VCR_CASSETTE'] || 'vendorificator') do
          super(*args)
        end
      else
        super(*args)
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

    def fail!(message, exception_message='I give up.')
      say_status('FATAL', message, :red)
      raise Thor::Error, 'I give up.'
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
