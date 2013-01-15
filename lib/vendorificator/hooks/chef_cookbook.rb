require 'chef/cookbook/metadata'

module Vendorificator::Hooks
  module ChefCookbookDependencies
    # Add required Chef cookbooks to vendor modules
    def dependencies
      ignored = Vendorificator::Config[:chef_cookbook_ignore_dependencies] || []
      metadata = File.join(self.work_dir, 'metadata.rb')

      unless File.exist?(metadata)
        shell.say_status 'WARNING', "Metadata of #{name} does not exist at #{metadata}, could not gather dependencies", :red
        return super
      end

      cbmd = Chef::Cookbook::Metadata.new
      cbmd.from_file(metadata)

      super + cbmd.dependencies.
        reject { |name, version| ignored.include?(name) }.
        map { |name, version| Vendorificator::Vendor::ChefCookbook.new(name) }
    end
  end
end
