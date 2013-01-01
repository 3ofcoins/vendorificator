require 'chef/cookbook/metadata'

module Vendorificator::Hooks
  module ChefCookbookDependencies
    # Add required Chef cookbooks to vendor modules
    def after_conjure_hook
      ignored = Vendorificator::Config[:chef_cookbook_ignore_dependencies] || []
      cookbook_path = Vendorificator::Config[:chef_cookbook_path] || []
      cookbook_path |= [ File.dirname(self.work_dir) ]

      cbmd = Chef::Cookbook::Metadata.new
      cbmd.from_file File.join(self.work_dir, 'metadata.rb')

      cbmd.dependencies.each do |name, version|
        # Don't add ignored cookbooks
        next if ignored.include?(name)

        work_dirs = Vendorificator::Config[:modules].map(&:work_dir)
        path = cookbook_path.map { |p| File.expand_path(File.join(p, name)) }

        # Don't add cookbooks which already have modules
        next unless (path & work_dirs).empty?

        shell.say_status :dependency, name, :yellow
        Vendorificator::Config.chef_cookbook(name)
      end

      super
    end
  end
end
