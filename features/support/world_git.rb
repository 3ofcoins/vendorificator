require 'fileutils'
require 'git'

module Vendorificator
  module TestSupport
    module Git
      def git(*args)
        @git ||= {}
        @git[args] ||= ::Git.init(*args)
      end

      def commit_file(path, contents, message=nil)
        message ||= "Added #{path}"
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, 'w') { |f| f.puts(contents) }
        git.add(path)
        git.commit(message)
      end

      def repo_clean?
        # FIXME: How to do that with ruby-git?
        `git status --porcelain` == ""
      end

      def branch
        git.current_branch
      end

      def branches
        git.branches.map(&:to_s)
      end

      def tags
        git.tags.map(&:name)
      end
    end
  end
end

World(Vendorificator::TestSupport::Git)
