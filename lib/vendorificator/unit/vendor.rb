module Vendorificator
  class Unit::Vendor < Unit

    def initialize(options)
      @vendor = options.delete(:vendor)
      super
    end

    def branch_name
      _join config[:branch_prefix], group, name
    end

    private

    def path
      @vendor.args[:path] || _join(group, name)
    end
  end
end
