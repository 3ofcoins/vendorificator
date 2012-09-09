require 'pathname'

require "vendorificator/version"

module Vendorificator
  class VendorfileNotFound < StandardError ; end

  module_function

  def vendorfile
    @vendorfile ||= find_vendorfile
  end

  def root
    vendorfile.dirname
  end

  def find_vendorfile
    given = ENV['VENDORFILE']
    return Pathname.new(given).expand_path if given && !given.empty?

    Pathname.pwd.ascend do |dir|
      vf = dir.join('Vendorfile')
      return vf if vf.exist?

      # avoid stepping above the tmp directory when testing
      if ENV['VENDORIFICATOR_SPEC_RUN'] &&
          dir.join('vendorificator.gemspec').exist?
         raise VendorfileNotFound
      end
    end

    raise VendorfileNotFound
  end
end
