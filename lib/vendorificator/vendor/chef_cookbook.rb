require 'net/http'
require 'uri'
require 'json'

require 'vendorificator/vendor/archive'
require 'vendorificator/hooks/chef_cookbook'

module Vendorificator
  class Vendor::ChefCookbook < Vendor::Archive
    include Hooks::ChefCookbookDependencies

    @method_name = :chef_cookbook
    @category = :cookbooks

    API_PREFIX = 'http://cookbooks.opscode.com/api/v1/cookbooks/'

    def initialize(environment, name, args={}, &block)
      args[:url] ||= true         # to avoid having name treated as url
      args[:filename] ||= "#{name}.tgz"

      super(environment, name, args, &block)
    end

    def api_data(v=nil)
      v = v.gsub(/[^0-9]/, '_') if v
      @api_data ||= {}
      @api_data[v] ||=
        begin
          url = "#{API_PREFIX}#{name}"
          url << "/versions/#{v}" if v
          JSON::load(Net::HTTP.get_response(URI.parse(url)).body)
        end
    end

    def cookbook_data
      @cookbook_data ||= api_data(version)
    end

    def upstream_version
      URI::parse(api_data['latest_version']).path.split('/').last.gsub('_', '.')
    end

    def url
      cookbook_data['file']
    end

    def conjure!
      super
      # Some Opscode Community tarballs include a confusing .git file,
      # we don't want this.
      FileUtils::rm_f '.git'
    end

    def conjure_commit_message
      "Conjured cookbook #{name} version #{version}\nOrigin: #{url}\nChecksum: #{conjured_checksum}\n"
    end

  end

  class Config
    register_module :chef_cookbook, Vendor::ChefCookbook
    option :chef_cookbook_ignore_dependencies
  end
end
