module Vendorificator
  class Overlay
    attr_reader :path

    def initialize(path)
      # Clears leading '/' from the path.
      @path = path.gsub(/\A\//, '')
    end
  end
end
