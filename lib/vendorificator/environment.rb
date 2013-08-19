require 'pathname'
require 'minigit'
require 'awesome_print'
require 'vendorificator/config'

module Vendorificator
  class Environment
    attr_reader :config
    attr_accessor :vendor_instances, :io

    def initialize(shell, verbosity = :default, vendorfile = nil, &block)
      @vendor_instances = []
      @io = IOProxy.new(shell, verbosity)
      @vendorfile = find_vendorfile(vendorfile)
      @vendor_block = block

      @config = Vendorificator::Config.new
      @config.environment = self
    end

    def shell
      io.shell
    end

    def say(*args)
      io.say(*args)
    end

    def say_status(*args)
      io.say_status(*args)
    end

    # Main MiniGit instance
    def git
      @git ||= MiniGit::new(config[:vendorfile_path])
    end

    # Git helpers
    def remotes
      @remotes ||= git.capturing.remote.lines.map(&:strip)
    end

    def current_branch
      git.capturing.rev_parse({:abbrev_ref => true}, 'HEAD').strip
    end

    def fast_forwardable?(to, from)
      git.capturing.merge_base(to, from).strip == from
    end

    # Public: Pulls all the remotes specified in options[:remote] or the config.
    #
    # options - The Hash of options.
    #
    # Returns nothing.
    def pull_all(options = {})
      load_vendorfile

      ensure_clean!
      remotes = options[:remote] ? options[:remote].split(',') : config[:remotes]
      remotes.each do |remote|
        indent :default, 'remote', remote do
          pull(remote, options)
        end
      end
    end

    # Public: Pulls a single remote and updates the branches.
    #
    # options - The Hash of options.
    #
    # Returns nothing.
    def pull(remote, options={})
      load_vendorfile

      raise RuntimeError, "Unknown remote #{remote}" unless remotes.include?(remote)

      git.fetch(remote)
      git.fetch({:tags => true}, remote)
      begin
        git.fetch(remote, 'refs/notes/vendor:refs/notes/vendor')
      rescue MiniGit::GitError  # ignore
      end

      ref_rx = /^refs\/remotes\/#{Regexp.quote(remote)}\//
      remote_branches = Hash[ git.capturing.show_ref.
        lines.
        map(&:split).
        map { |sha, name| name =~ ref_rx ? [$', sha] : nil }.
        compact ]

      each_vendor_instance do |mod|
        ours = mod.head
        theirs = remote_branches[mod.branch_name]
        if theirs
          if not ours
            say_status :default, 'new', mod.branch_name, :yellow
            git.branch({:track => true}, mod.branch_name, theirs) unless options[:dry_run]
          elsif ours == theirs
            say_status :default, 'unchanged', mod.branch_name
          elsif fast_forwardable?(theirs, ours)
            say_status :default, 'updated', mod.name, :yellow
            mod.in_branch { git.merge({:ff_only => true}, theirs) } unless options[:dry_run]
          elsif fast_forwardable?(ours, theirs)
            say_status :default, 'older', mod.branch_name
          else
            say_status :default, 'complicated', mod.branch_name, :red
          end
        else
          say_status :default, 'unknown', mod.branch_name
        end
      end
    end

    # Public: Displays info about the last merged version of module.
    #
    # mod - String with the module name
    # options - Hash containing options
    #
    # Returns nothing.
    def info(mod_name, options = {})
      load_vendorfile

      if vendor = find_vendor_instance_by_name(mod_name)
        say :default, "Module name: #{vendor.name}\n"
        say :default, "Module category: #{vendor.category}\n"
        say :default, "Module merged version: #{vendor.merged_version}\n"
        say :default, "Module merged notes: #{vendor.merged_notes.ai}\n"
      elsif (commit = Commit.new(mod_name, git)).exists?
        say :default, "Branches that contain this commit: #{commit.branches.join(', ')}\n"
        say :default, "Vendorificator notes on this commit: #{commit.notes.ai}\n"
      else
        say :default, "Module or ref #{mod_name.inspect} not found."
      end
    end

    # Public: Push changes on module branches.
    #
    # options - The Hash containing options
    #
    # Returns nothing.
    def push(options = {})
      load_vendorfile

      ensure_clean!

      pushable = []
      each_vendor_instance { |mod| pushable += mod.pushable_refs }

      pushable << 'refs/notes/vendor' if has_notes?

      remotes = options[:remote] ? options[:remote].split(',') : config[:remotes]
      remotes.each do |remote|
        git.push remote, pushable
      end
    end

    # Public: Runs all the vendor modules.
    #
    # options - The Hash of options.
    #
    # Returns nothing.
    def sync(options = {})
      load_vendorfile

      ensure_clean!
      config[:use_upstream_version] = options[:update]
      metadata = metadata_snapshot

      each_vendor_instance(*options[:modules]) do |mod|
        say_status :default, :module, mod.name
        indent do
          mod.run!(:metadata => metadata)
        end
      end
    end

    # Public: Goes through all the Vendor instances and runs the block
    #
    # modules - ?
    #
    # Returns nothing.
    def each_vendor_instance(*modules)
      modpaths = modules.map { |m| File.expand_path(m) }

      # We don't use @vendor_instances.each here, because Vendor#run! is
      # explicitly allowed to append to instantiate new dependencies, and #each
      # fails to catch up on some Ruby implementations.
      i = 0
      while true
        break if i >= @vendor_instances.length
        mod = @vendor_instances[i]
        yield mod if modules.empty? ||
          modules.include?(mod.name) ||
          modpaths.include?(mod.work_dir)
        i += 1
      end
    end

    # Public: Checks if the repository is clean.
    #
    # Returns boolean answer to the question.
    def clean?
      # copy code from http://stackoverflow.com/a/3879077/16390
      git.update_index '-q', '--ignore-submodules', '--refresh'
      git.diff_files '--quiet', '--ignore-submodules', '--'
      git.diff_index '--cached', '--quiet', 'HEAD', '--ignore-submodules', '--'
      true
    rescue MiniGit::GitError
      false
    end

    def metadata_snapshot
      {
        :vendorificator_version => ::Vendorificator::VERSION,
        :current_branch => git.capturing.rev_parse({:abbrev_ref => true}, 'HEAD').strip,
        :current_sha => git.capturing.rev_parse('HEAD').strip,
        :git_describe => (git.capturing.describe(:always => true).strip rescue '')
      }
    end

    # Public: returns `config[:root_dir]` relative to Git repository root
    def relative_root_dir
      @relative_root_dir ||= config[:root_dir].relative_path_from(
        Pathname.new(git.git_work_tree)
      )
    end

    # Public: Returns module with given name
    def [](name)
      vendor_instances.find { |v| v.name == name }
    end

    # Public: Loads the vendorfile.
    #
    # Returns nothing.
    def load_vendorfile
      raise RuntimeError, 'Vendorfile has been already loaded!' if @vendorfile_loaded

      if @vendorfile
        @config.read_file @vendorfile.to_s
      else
        raise MissingVendorfileError unless @vendor_block
      end
      @config.instance_eval(&@vendor_block) if @vendor_block

      each_vendor_instance{ |mod| mod.compute_dependencies! }

      @vendorfile_loaded = true
    end

    # Public: Checks if vendorfile has been already loaded.
    #
    # Returns boolean.
    def vendorfile_loaded?
      defined?(@vendorfile_loaded) && @vendorfile_loaded
    end

    private

    # Private: Finds a vendor instance by module name.
    #
    # mod_name - The String containing the module name.
    #
    # Returns Vendor instance.
    def find_vendor_instance_by_name(mod_name)
      each_vendor_instance do |mod|
        return mod if mod.name == mod_name
      end
      nil
    end

    # Private: Finds the vendorfile to use.
    #
    # given - the optional String containing vendorfile path.
    #
    # Returns a String containing the vendorfile path.
    def find_vendorfile(given = nil)
      given = [given, ENV['VENDORFILE']].find do |candidate|
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
          break
        end
      end

      return nil
    end

    # Private: Aborts on a dirty repository.
    #
    # Returns nothing.
    def ensure_clean!
      raise DirtyRepoError unless clean?
    end

    # Private: Indents the output.
    #
    # Returns nothing.
    def indent(verb_level = :default, *args, &block)
      say_status verb_level, *args unless args.empty?
      shell.padding += 1 if shell
      yield
    ensure
      shell.padding -= 1 if shell
    end

    # Private: Checks if there are git vendor notes.
    #
    # Returns true/false.
    def has_notes?
      git.capturing.rev_parse({:quiet => true, :verify => true}, 'refs/notes/vendor')
      true
    rescue MiniGit::GitError
      false
    end

  end
end
