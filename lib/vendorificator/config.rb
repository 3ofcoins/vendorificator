require 'pathname'

module Vendorificator
  class Config
    attr_accessor :environment
    attr_reader :metadata, :overlay_instance

    @defaults = {}
    @modules = {}

    def self.defaults
      @defaults
    end

    def self.modules
      @modules
    end

    def self.option(name, default = nil, &block)
      define_method name do |*args|
        if args.size == 0
          @configuration[name.to_sym]
        elsif args.size == 1
          @configuration[name.to_sym] = args.first
        else
          raise 'Unsupported number of arguments (expected 0 or 1).'
        end
      end
      @defaults[name.to_sym] = default if default
    end

    def self.register_module(name, klass)
      @modules[name.to_sym] = klass
    end

    def initialize(params = {})
      @fake_mode = check_fake_mode
      @configuration = self.class.defaults.merge(params)
      @metadata = {}
    end

    def read_file(filename)
      pathname = Pathname.new(filename).cleanpath.expand_path

      @configuration[:vendorfile_path] = pathname
      @configuration[:root_dir] = if pathname.basename.to_s == 'vendor.rb' &&
                          pathname.dirname.basename.to_s == 'config'
          pathname.dirname.dirname
        else
          pathname.dirname
        end

      instance_eval(IO.read(filename), filename, 1)
    end

    def configure(&block)
      block.call @configuration
    end

    def [](key)
      @configuration[key]
    end

    def []=(key, value)
      @configuration[key] = value
    end

    def modules
      self.class.modules
    end

    def annotate key, value
      @metadata.merge!({key => value})
    end

    def method_missing(method_symbol, *args, &block)
      if modules.keys.include? method_symbol
        modules[method_symbol].new(environment, args.delete_at(0).to_s, *args, &block)
      else
        super
      end
    end

    def overlay(name, options = {}, &block)
      @overlay_instance = Segment::Overlay.new(
        environment: environment, overlay_opts: options.merge(name: name)
      )
      environment.segments << @overlay_instance
      yield
    ensure
      @overlay_instance = nil
    end

    # Public: Returns information whether we work in the fake mode.
    #
    # Returns true/false.
    def fake_mode?
      @fake_mode
    end

    option :basedir, 'vendor'
    option :branch_prefix, 'vendor'
    option :remotes, %w(origin)

    private

    # Private: Check if we should work in the fake mode.
    #
    # Returns true/false.
    def check_fake_mode
      setting = MiniGit::Capturing.git(:config, 'vendorificator.stub').strip
      ['', 'false', '0', 'no'].include?(setting) ? false : true
    rescue MiniGit::GitError
      false
    end

  end
end
