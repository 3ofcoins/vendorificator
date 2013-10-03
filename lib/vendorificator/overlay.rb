module Vendorificator
  class Overlay
    attr_reader :path, :segments

    def initialize(path)
      # Clears leading '/' from the path.
      @path = (adj_path = path.gsub(/\A\//, '')) != '' ? adj_path : nil
      @segments = []
    end

  end
end
