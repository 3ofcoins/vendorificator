module Vendorificator::Hooks
  module ChefCookbookDependencies
    def initialize(*args)
      require 'chef/cookbook/metadata'
      super
    end

    def compute_dependencies!
      super

      # Dependencies
      ign = self.args.key?(:ignore_dependencies) ?
        args[:ignore_dependencies] :
          Vendorificator::Config[:chef_cookbook_ignore_dependencies]

      if !ign || ign.respond_to?(:include?)
        metadata = File.join(self.work_dir, 'metadata.rb')

        unless File.exist?(metadata)
          shell.say_status 'WARNING', "Metadata of #{name} does not exist at #{metadata}, could not gather dependencies", :red
          return super
        end

        cbmd = Chef::Cookbook::Metadata.new
        cbmd.from_file(metadata)

        basedir = Pathname.new(work_dir).dirname

        # All of cookbook's dependencies
        deps = cbmd.dependencies.map(&:first)

        # Reject ignored dependencies, if there's a list
        deps.reject! { |dep| ign.include?(dep) } if ign

        # Reject dependencies that already have a module
        deps.reject! do |dep|
          dir = basedir.join(dep).to_s
          Vendorificator::Vendor.instances.any? do |vi|
            vi.work_dir == dir
          end
        end

        # Create module for the dependencies
        deps.each do |dep|
          Vendorificator::Vendor::ChefCookbook.new(environment, dep)
        end
      end
    end
  end
end
