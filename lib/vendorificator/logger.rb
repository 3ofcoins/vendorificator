require 'stringio'

module Vendorificator
  class Logger
    attr_reader :verbosity, :shell

    def initialize(shell, verbosity = :default)
      @stdout_cache = StringIO.new
      @stderr_cache = StringIO.new
    end

    def write(value, io = :stdout)
      case io
      when :stdout
        @stdout_cache << value
      when :stderr
        @stderr_cache << value
      else
        raise "Unexpected IO channel: #{io.inspect}"
      end
    end
  end
end
