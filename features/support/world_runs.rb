require 'mixlib/shellout'

class String
  def strip_console_escapes
    self.gsub(/\e\[[^m]{1,5}m/,'')
  end

  def indent(amount, char=' ')
    prefix = char * amount
    lines.map { |ln| ln =~ /^\s*$/ ? ln : prefix+ln }.join
  end
end

module Vendorificator
  module TestSupport
    module RunsCommands
      def command
        raise RuntimeError, "No command has run yet!" unless @command
        @command
      end

      def run(*command_args)
        opts = {}
        opts = command_args.pop if command_args.last.is_a?(Hash)

        # We need to clear out Git environment variables left here by
        # the Git gem.
        opts[:environment] ||= {}
        opts[:environment].merge!(
          'GIT_DIR' => nil,
          'GIT_INDEX_FILE' => nil,
          'GIT_WORK_TREE' => nil)

        command_args.push opts
        @command = Mixlib::ShellOut.new(*command_args)

        command.run_command
        print_command_result if ENV['VERBOSE']
      end

      def command_succeeded
        command.error!
        true
      rescue Mixlib::ShellOut::ShellCommandFailed
        print_command_result
        false
      end

      def command_stdout
        command.stdout.strip_console_escapes
      end

      def command_stderr
        command.stderr.strip_console_escapes
      end

      def print_command_result
        puts <<EOF

-------- BEGIN #{command.command.inspect} --------
Exit status: #{command.exitstatus}
Execution time: #{command.execution_time}
Stdout:
#{command_stdout.indent(4)}
Stderr:
#{command_stderr.indent(4)}
--------  END #{command.command.inspect}  --------

EOF
      end
    end
  end
end

World(Vendorificator::TestSupport::RunsCommands)
