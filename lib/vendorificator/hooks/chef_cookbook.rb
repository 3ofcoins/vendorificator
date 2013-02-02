require 'chef/cookbook/metadata'

module Vendorificator::Hooks
  module ChefCookbookDependencies
    # Add required Chef cookbooks to vendor modules
    def dependencies
      ignored = Vendorificator::Config[:chef_cookbook_ignore_dependencies]
      metadata = File.join(self.work_dir, 'metadata.rb')

      unless File.exist?(metadata)
        shell.say_status 'WARNING', "Metadata of #{name} does not exist at #{metadata}, could not gather dependencies", :red
        return super
      end

      cbmd = Chef::Cookbook::Metadata.new
      cbmd.from_file(metadata)

      if ignored && !ignored.respond_to?(:include?)
        # ignored is a truthy value that's not a set-like thing, so we
        # ignore all dependencies altogether.
        super
      else
        deps = cbmd.dependencies.map(&:first)
        deps.reject! { |n| ignored.include?(n) } if ignored.respond_to?(:include?)
        deps.map! { |n| Vendorificator::Vendor::ChefCookbook.new(n) }
        super + deps
      end
    end
  end
end
