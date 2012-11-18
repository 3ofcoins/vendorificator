require 'thor'

require 'vendorificator'

module Vendorificator
  class VendorfileNotFound < StandardError ; end

  class CLI < Thor
    include Vendorificator

    check_unknown_options!
    default_task :sync

    class_option :file, :aliases => '-f', :type => :string, :banner => 'PATH'

    def initialize(*args)
      super
      Vendorificator::Config.from_file(find_vendorfile)
    end

    desc :sync, "Download new or updated vendor files"
    def sync
    end

    private

    # Find proper Vendorfile
    def find_vendorfile
      given = options.file || ENV['VENDORFILE']
      return Pathname.new(given).expand_path if given && !given.empty?

      Pathname.pwd.ascend do |dir|
        vf = dir.join('Vendorfile')
        return vf if vf.exist?

        vf = dir.join('config/vendor.rb')
        return vf if vf.exist?

        # avoid stepping above the tmp directory when testing
        if ENV['VENDORIFICATOR_SPEC_RUN'] &&
            dir.join('vendorificator.gemspec').exist?
          raise Vendorificator::VendorfileNotFound
        end
      end

      raise Vendorificator::VendorfileNotFound
    end

  end
end
