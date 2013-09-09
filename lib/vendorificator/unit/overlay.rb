module Vendorificator
  class Unit::Overlay < Unit
    attr_reader :overlay

    def initialize(options)
      @vendor = options.delete(:vendor)
      @overlay = config.overlay_instance
      super
    end

    def branch_name
      _join config[:branch_prefix], 'overlay', overlay.path, 'layer', group, name
    end

    private

    def path
      @vendor.args[:path] || _join(overlay.path, group, name)
    end

  end
end

