require 'digest'
require 'open-uri'
require 'tempfile'
require 'uri'

require 'vendorificator/vendor'

class Vendorificator::Vendor::Download < Vendorificator::Vendor
  arg_reader :url
  attr_reader :conjured_checksum

  def initialize(environment, name, args={}, &block)
    no_url_given = !args[:url]

    args[:url] ||= name
    name = URI::parse(args[:url]).path.split('/').last if no_url_given

    super(environment, name, args, &block)
  end

  def path
    args[:path] || category
  end

  def conjure!
    shell.say_status :download, url
    File.open name, 'w' do |outf|
      outf.write( open(url).read )
    end
    @conjured_checksum = Digest::SHA256.file(name).hexdigest
  end

  def upstream_version
    conjured_checksum || Digest::SHA256.hexdigest( open(url).read )
  end

  def conjure_commit_message
    rv = "Conjured #{name} from #{url}\nChecksum: #{conjured_checksum}"
    rv << "Version: #{args[:version]}" if args[:version]
    rv
  end

  install!
end
