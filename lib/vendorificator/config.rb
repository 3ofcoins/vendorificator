require 'pathname'

require 'mixlib/config'

module Vendorificator
  class Config
    extend Mixlib::Config

    attr_accessor :environment

    configure do |c|
      c[:basedir] = 'vendor'
      c[:branch_prefix] = 'vendor'
      c[:modules] = []
      c[:remotes] = %w(origin)
    end

    def self.from_file(filename)
      pathname = Pathname.new(filename).cleanpath.expand_path

      self[:vendorfile_path] = pathname
      self[:root_dir] =
        if ( pathname.basename.to_s == 'vendor.rb' &&
               pathname.dirname.basename.to_s == 'config' )
          # Correctly recognize root dir if main config is 'config/vendor.rb'
          pathname.dirname.dirname
        else
          pathname.dirname
        end

      super(pathname.to_s)
    end
  end
end
