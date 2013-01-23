require 'grit'

module Vendorificator
  class Repo < Grit::Repo
    # True if repository doesn't contain uncommitted changes.
    def clean?
      # copy code from http://stackoverflow.com/a/3879077/16390
      git.native :update_index, {}, '-q', '--ignore-submodules', '--refresh'
      git.native :diff_files, {:raise => true}, '--quiet', '--ignore-submodules', '--'
      git.native :diff_index, {:raise => true}, '--cached', '--quiet', 'HEAD', '--ignore-submodules', '--'
      true
    rescue Grit::Git::CommandFailed
      false
    end

    # Update vendor branches & tags from an upstream repository
    def pull(remote, options={})
      raise RuntimeError, "Unknown remote #{remote}" unless remote_list.include?(remote)

      git.fetch({}, remote)
      git.fetch({:tags => true}, remote)

      ref_rx = /^#{Regexp.quote(remote)}\//
      remote_branches = Hash[remotes.map{|r| [$',r] if r.name =~ ref_rx }.compact]

      # FIXME: should we depend on Vendorificator::Config here?
      Vendorificator::Config.each_module do |mod|
        remote_head = remote_branches[mod.branch_name]
        ours = mod.head && mod.head.commit.sha
        theirs = remote_head && remote_head.commit.sha

        if remote_head
          if not mod.head
            say_status 'new', mod.branch_name, :yellow
            git.branch({:track=>true}, mod.branch_name, remote_head.name) unless options[:dry_run]
          elsif ours == theirs
            say_status 'unchanged', mod.branch_name
          elsif fast_forwardable?(theirs, ours)
            say_status 'updated', mod.name, :yellow
            unless options[:dry_run]
              mod.in_branch do
                git.merge({:ff_only => true}, remote_head.name)
              end
            end
          elsif fast_forwardable?(ours, theirs)
            say_status 'older', mod.branch_name
          else
            say_status 'complicated', mod.branch_name, :red
            indent do
              say 'Merge it yourself.'
            end
          end
        else
          say_status 'unknown', mod.branch_name
        end
      end

      private

      def conf
        Vendorificator::Config
      end

      def say_status(*args)
        conf[:shell].say_status(*args) if conf[:shell]
      end
    end
  end
end
