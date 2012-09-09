require 'pathname'
require 'yaml'

require 'vendorificator'
require 'vendorificator/vendor'

module Vendorificator
  class Config
    include Vendorificator

    attr_accessor :basedir, :repository, :branch_prefix
    attr_reader :lockfile, :lockfile_data

    def initialize(vendorfile_path=nil)
      vendorfile_path ||= vendorfile

      # Config file paths
      @vendorfile = (
        vendorfile_path.is_a?(Pathname) ?
        vendorfile_path :
        Pathname.new(vendorfile_path) ).cleanpath
      @lockfile = Pathname.new(@vendorfile.to_s + '.lock')

      # Load lock data
      @lockfile_data = YAML::load_file(@lockfile.to_s) if @lockfile.exist?

      # Defaults for global config options
      @repository = Vendorificator::root
      @locked = nil
      @basedir = 'vendor'
      @branch_prefix = 'vendor/'
      @modules = []

      # Read and evaluate the Vendorfile
      instance_eval(@vendorfile.read, @vendorfile.to_s, 1)

      # Fixup the data that reading Vendorfile may have left in a funny state
      @repository = Pathname.new(@repository) unless @repository.is_a?(Pathname)
    end

    def self.defvendor(cls, method_name=nil)
      method_name ||= cls.name.split('::').last.downcase.to_sym
      define_method(method_name) do |*args|
        @modules << cls.new(self, *args)
      end
    end

    defvendor Vendorificator::Vendor
    defvendor Vendorificator::Archive
    defvendor Vendorificator::Git
  end
end
