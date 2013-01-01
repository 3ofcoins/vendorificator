require 'net/http'
require 'uri'
require 'json'

require 'vendorificator/vendor/archive'

class Vendorificator::Vendor::ChefCookbook < Vendorificator::Vendor::Archive
  @method_name = :chef_cookbook
  API_PREFIX = 'http://cookbooks.opscode.com/api/v1/cookbooks/'

  def initialize(name, args={}, &block)
    uri = if args[:version]
            "#{API_PREFIX}#{name}/versions/#{args[:version].gsub(/[^0-9]/, '_')}"
          else
            JSON.load(
              Net::HTTP.get_response(URI.parse("#{API_PREFIX}#{name}")).body
            )['latest_version']
          end

    cookbook_data = JSON.load(Net::HTTP.get_response(URI.parse(uri)).body)

    args[:version] = cookbook_data['version']
    args[:url] = cookbook_data['file']
    args[:cookbook_api_data] = cookbook_data

    super(name, args, &block)
  end

  def branch_name
    "#{Vendorificator::Config[:branch_prefix]}cookbooks/#{name}"
  end

  def work_subdir
    File.join(Vendorificator::Config[:basedir], 'cookbooks', path||name)
  end

  def conjure_tag_name
    "vendor/cookbooks/#{name}/#{version || filename}"
  end

  def conjure_commit_message
    "Conjured cookbook #{name} version #{version}\nOrigin: #{url}\nChecksum: #{conjured_checksum}\n"
  end

  install!
end
