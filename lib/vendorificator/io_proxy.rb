require 'stringio'

module Vendorificator
  class IOProxy
    attr_reader :shell

    def initialize(shell, verbosity = :default)
      @shell = shell
      @verbosity = verbosity
    end

    def puts(value, verb_level = :default)
      @orig_stdout.puts value if should_speak?(verb_level)
    end

    def say_status(verb_level, *args)
      @shell.say_status(*args) if @shell && should_speak?(verb_level)
    end

    def say(verb_level, *args)
      @shell.say(*args) if @shell && should_speak?(verb_level)
    end

    private

    def should_speak?(level)
      levels = {:quiet => 1, :default => 2, :chatty => 3, :debug => 9}
      raise "Unknown verbosity level: #{level.inspect}" if levels[level].nil?

      levels[level] <= levels[@verbosity]
    end
  end
end

