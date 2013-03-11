require 'pathname'

module Vendorificator
  class Config
    attr_accessor :environment

    @defaults = {
      :basedir => 'vendor',
      :branch_prefix => 'vendor',
      :remotes => %w(origin)
    }
    @modules = {}

    def self.defaults
      @defaults
    end

    def self.modules
      @modules
    end

    def self.option(name, default = nil, &block)
      define_method name do |value|
        @configuration[name.to_sym] = value
      end
      @defaults[name.to_sym] = default if default
    end

    def self.register_module(name, klass)
      @modules[name.to_sym] = klass
    end

    def initialize(params = {})
      @configuration = self.class.defaults.merge(params)
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

    def method_missing(method_symbol, *args, &block)
      if modules.keys.include? method_symbol
        modules[method_symbol].new(environment, args.delete_at(0).to_s, *args, &block)
      else
        super
      end
    end

  end
end
