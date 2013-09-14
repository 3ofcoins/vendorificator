module Vendorificator
  class Segment::Vendor < Segment
    attr_reader :overlay

    def initialize(options)
      @vendor = options.delete(:vendor)
      @overlay = options.delete(:overlay)
      super
    end

    def name
      @vendor.name
    end

    def branch_name
      _join config[:branch_prefix], group, name
    end

    def compute_dependencies!
      @vendor.compute_dependencies!
    end

    private

    def path
      @vendor.args[:path] || _join(group, name)
    end
  end
end
