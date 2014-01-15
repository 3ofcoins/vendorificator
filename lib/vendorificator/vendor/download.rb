require 'digest'
require 'open-uri'
require 'tempfile'
require 'uri'

require 'vendorificator/vendor'

module Vendorificator
  class Vendor::Download < Vendor
    arg_reader :url
    attr_reader :conjured_checksum, :conjured_filesize

    def path
      args[:path] || group
    end

    def conjure!
      say_status :default, :download, url
      File.open name, 'w' do |outf|
        outf.write( open(url).read )
      end
      @conjured_checksum = Digest::SHA256.file(name).hexdigest
      @conjured_filesize = File.size(name)
      add_download_metadata
    end

    def upstream_version
      conjured_checksum || Digest::SHA256.hexdigest( open(url).read )
    end

    def conjure_commit_message
      rv = "Conjured #{name} from #{url}\nChecksum: #{conjured_checksum}"
      rv << "Version: #{args[:version]}" if args[:version]
      rv
    end

    private

    def parse_initialize_args(args = {})
      unless args[:url]
        args[:url] ||= @name
        @name = URI::parse(args[:url]).path.split('/').last
      end

      args
    end

    def add_download_metadata
      @metadata[:download_checksum] = conjured_checksum
      @metadata[:download_filesize] = conjured_filesize
      @metadata[:download_url] = url
    end
  end

  class Config
    register_module :download, Vendor::Download
  end
end
