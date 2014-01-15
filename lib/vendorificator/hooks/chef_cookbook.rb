module Vendorificator::Hooks
  module ChefCookbookDependencies
    class FakeMetadata
      attr_reader :dependencies
      def initialize ; @dependencies = [] ; end
      def from_file(filename) ; self.instance_eval(IO.read(filename), filename, 1) ; end
      def depends(*args) ; @dependencies << args ; end
      def method_missing(method, *args) ; end
    end

    def initialize(*args)
      begin
      end
      super
    end

    def compute_dependencies!
      super

      # Dependencies
      ign = self.args.key?(:ignore_dependencies) ?
        args[:ignore_dependencies] :
          environment.config[:chef_cookbook_ignore_dependencies]

      if !ign || ign.respond_to?(:include?)
        metadata = File.join(work_dir, 'metadata.rb')

        unless File.exist?(metadata)
          say_status :quiet, 'WARNING', "Metadata of #{name} does not exist at #{metadata}, could not gather dependencies", :red
          return super
        end

        cbmd = Vendorificator::Hooks::ChefCookbookDependencies.metadata_class.new
        cbmd.from_file(metadata)

        basedir = Pathname.new(work_dir).dirname

        # All of cookbook's dependencies
        deps = cbmd.dependencies.map(&:first)

        # Reject ignored dependencies, if there's a list
        deps.reject! { |dep| ign.include?(dep) } if ign

        # Reject dependencies that already have a module
        deps.reject! do |dep|
          dir = basedir.join(dep).to_s
          environment.segments.any? do |vi|
            vi.work_dir == dir
          end
        end

        # Create module for the dependencies
        deps.each do |dep|
          Vendorificator::Vendor::ChefCookbook.new(environment, dep)
        end
      end
    end

    private

    def self.metadata_class
      @metadata_class ||=
        begin
          require 'chef/cookbook/metadata' unless defined?(Chef::Cookbook::Metadata)
          Chef::Cookbook::Metadata
        rescue LoadError
          # FIXME: warn
          FakeMetadata
        end
    end
  end
end
