require 'pathname'

require 'mixlib/config'

module Vendorificator
  class Config
    extend Mixlib::Config

    configure do |c|
      c[:root] = Pathname.getwd
      c[:basedir] = 'vendor'
      c[:branch_prefix] = 'vendor/'
      c[:modules] = {}
    end

    def self.from_file(filename)
      pathname = Pathname.new(filename).cleanpath.expand_path
      self[:root_dir] = 
        if ( pathname.basename.to_s == 'vendor.rb' &&
               pathname.dirname.basename.to_s == 'config' )
          # Correctly recognize root dir if main config is 'config/vendor.rb'
          pathname.dirname.dirname
        else
          pathname.dirname
        end
      self[:vendorfile_path] = pathname
      self[:lockfile_path] = pathname.dirname.join(pathname.basename.to_s + '.lock')
      super(pathname.to_s)
    end
  end
end
