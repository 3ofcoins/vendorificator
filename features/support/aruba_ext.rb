require 'shellwords'

module Vendorificator
  module TestSupport
    module ArubaExt
      def last_process
        processes.last.last
      end

      def last_stdout
        unescape last_process.stdout
      end

      def last_stderr
        unescape last_process.stderr
      end

      def last_output
        unescape(last_stdout + last_stderr)
      end

      def without_bundler(cmd)
        cmd = %w[ RUBYOPT BUNDLE_PATH BUNDLE_BIN_PATH BUNDLE_GEMFILE
                ].map { |v| "unset #{v} ; " }.join << cmd
        "sh -c #{Shellwords.escape(cmd)}"
      end
    end
  end
end

World(Vendorificator::TestSupport::ArubaExt)
