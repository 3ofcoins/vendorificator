module Vendorificator
  class Overlay
    attr_reader :path

    def initialize(path)
      @path = path
    end
  end
end
