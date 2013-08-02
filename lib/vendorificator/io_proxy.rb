require 'stringio'

module Vendorificator
  class IOProxy < StringIO
    attr_reader :shell

    def initialize(shell, verbosity = :default)
      @shell = shell
      @verbosity = verbosity

      super()
      capture_stdout
    end

    def puts(value, verb_level = :default)
      @orig_stdout.puts value if should_speak?(verb_level)
      super
    end

    def say_status(verb_level, *args)
      write args[0..1].join('  ' * @shell.padding)
      @shell.say_status(*args) if @shell && should_speak?(verb_level)
    end

    def say(verb_level, *args)
      write args[0]
      @shell.say(*args) if @shell && should_speak?(verb_level)
    end

    private

    def capture_stdout
      @orig_stdout = $stdout

      $stdout = self
    end

    def should_speak?(level)
      levels = {:quiet => 1, :default => 2, :chatty => 3, :debug => 9}
      raise "Unknown verbosity level: #{level.inspect}" if levels[level].nil?

      levels[level] <= levels[@verbosity]
    end
  end
end

