require 'pathname'

module Vendorificator
  class Config
    attr_accessor :environment
    attr_accessor :modules

    class << self
      def option(name, default = nil, &block)
        define_method name do |value|
          @configuration[name.to_sym] = value
        end
      end
    end

    def initialize(params = {})
      @configuration = {
        :basedir => 'vendor',
        :branch_prefix => 'vendor',
        :remotes => %w(origin)
      }.merge(params)
      @modules = {
        :git => Vendor::Git,
        :archive => Vendor::Archive,
        :chef_cookbook => Vendor::ChefCookbook,
        :download => Vendor::Download,
        :vendor => Vendor
      }
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

    def method_missing(method_symbol, *args, &block)
      if @modules.keys.include? method_symbol
        @modules[method_symbol].new(environment, args.delete_at(0).to_s, *args, &block)
      else
        super
      end
    end

  end
end
