require 'pathname'

require 'minigit'

require 'vendorificator/config'

module Vendorificator
  class Environment
    attr_reader :config
    attr_accessor :shell

    def initialize(vendorfile=nil)
      @config = Vendorificator::Config.new
      @config.environment = self
      @config.read_file(self.class.find_vendorfile(vendorfile).to_s)
      Vendorificator::Vendor.compute_dependencies!
    end

    def say_status(*args)
      shell.say_status(*args) if shell
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

    def clean?
      # copy code from http://stackoverflow.com/a/3879077/16390
      git.update_index :q => true, :ignore_submodules => true, :refresh => true
      git.diff_files '--quiet', '--ignore-submodules', '--'
      git.diff_index '--cached', '--quiet', 'HEAD', '--ignore-submodules', '--'
      true
    rescue MiniGit::GitError
      false
    end

    def pull(remote, options={})
      raise RuntimeError, "Unknown remote #{remote}" unless remotes.include?(remote)

      git.fetch(remote)
      git.fetch({:tags => true}, remote)

      ref_rx = /^refs\/remotes\/#{Regexp.quote(remote)}\//
      remote_branches = Hash[ git.capturing.show_ref.
        lines.
        map(&:split).
        map { |sha, name| name =~ ref_rx ? [$', sha] : nil }.
        compact ]

      Vendorificator::Vendor.each do |mod|
        ours = mod.head
        theirs = remote_branches[mod.branch_name]
        if theirs
          if not ours
            say_status 'new', mod.branch_name, :yellow
            git.branch({:track=>true}, mod.branch_name, remote_head.name) unless options[:dry_run]
          elsif ours == theirs
            say_status 'unchanged', mod.branch_name
          elsif fast_forwardable?(theirs, ours)
            say_status 'updated', mod.name, :yellow
            mod.in_branch { git.merge({:ff_only => true}, theirs) } unless options[:dry_run]
          elsif fast_forwardable?(ours, theirs)
            say_status 'older', mod.branch_name
          else
            say_status 'complicated', mod.branch_name, :red
          end
        else
          say_status 'unknown', mod.branch_name
        end
      end

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
