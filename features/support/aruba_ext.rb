require 'shellwords'
require 'stringio'

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

      def with_redirected_stdout(&block)
        redirect_stdout
        yield
      ensure
        bring_back_stdout
      end

      def mock_stdout
        unescape @stdout_cache
      end

      def mock_stderr
        unescape @stderr_cache
      end

      def mock_output
        mock_stdout + mock_stderr
      end

      private

      def redirect_stdout
        @stdout_cache = ''
        @stderr_cache = ''

        @stdout_redirected = true
        @orig_stdout = $stdout
        @orig_stderr = $stderr
        $stdout = @mock_stdout = StringIO.new
        $stderr = @mock_stderr = StringIO.new
      end

      def bring_back_stdout
        @stdout_cache = @mock_stderr.string
        @stderr_cache = @mock_stdout.string

        @stdout_redirected = false
        $stdout = @orig_stdout
        $stderr = @orig_stderr
        @orig_stdout = @mock_stdout = nil
        @orig_stderr = @mock_stderr = nil
      end
    end
  end
end

World(Vendorificator::TestSupport::ArubaExt)
