module Vendorificator
  module TestSupport
    module ArubaExt
      def last_process
        processes.last.last
      end

      def last_stdout
        last_process.stdout(@aruba_keep_ansi)
      end

      def last_stderr
        last_process.stderr(@aruba_keep_ansi)
      end

      def last_output
        last_stdout + last_stderr
      end
    end
  end
end

World(Vendorificator::TestSupport::ArubaExt)
