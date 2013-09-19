module Vendorificator
  class Overlay
    attr_reader :path, :segments

    def initialize(path)
      # Clears leading '/' from the path.
      @path = path.gsub(/\A\//, '')
      @segments = []
    end

  end
end
