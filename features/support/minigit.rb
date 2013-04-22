require 'minigit'

module Vendorificator
  module TestSupport
    module MiniGit
      module MiniGitExt
        def refs(kind)
          show_ref(kind => true).lines.
            map { |ln| ln =~ /[0-9a-f]{40} refs\/#{kind}\// and $'.strip }.
            compact
        rescue ::MiniGit::GitError
          []
        end

        def heads
          refs(:heads)
        end

        def tags
          refs(:tags)
        end
      end

      def git
        @git ||= ::MiniGit::Capturing.new(current_dir)
      end

      def remote_git
        @remote_git ||= ::MiniGit::Capturing.new(current_dir + '/../remote-repository')
      end
    end
  end
end

class MiniGit
  include Vendorificator::TestSupport::MiniGit::MiniGitExt
end

MiniGit.debug = true if ENV['DEBUG']

World(Vendorificator::TestSupport::MiniGit)
