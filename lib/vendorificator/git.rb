require 'grit'

module Vendorificator
  class Git
    attr_reader :repo

    def initialize(*args)
      @repo = Grit::Repo.new(*args)
    end

    def git(*args)
      repo.git.native(*args)
    end

    def ensure_clean_repo
      # copy code from http://stackoverflow.com/a/3879077/16390
      git :update_index, {}, '-q', '--ignore-submodules', '--refresh'
      git :diff_files, {:raise => true}, '--quiet', '--ignore-submodules', '--'
      git :diff_index, {:raise => true}, '--cached', '--quiet', 'HEAD', '--ignore-submodules', '--'
    rescue Grit::Git::CommandFailed
      raise RuntimeError, "Git repository is not clean."
    end
  end
end
