require 'thor'

require 'vendorificator'
require 'vendorificator/config'

module Vendorificator
  class CLI < Thor
    include Vendorificator

    check_unknown_options!
    default_task :sync

    desc :sync, "Download new or updated vendor files"
    def sync
      cfg = Vendorificator::Config.new
    end
  end
end
