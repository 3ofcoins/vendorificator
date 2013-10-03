module Vendorificator
  class Overlay
    attr_reader :path, :name, :segments

    def initialize(options = {})
      @name = strip_leading_slash(options[:name])
      @path = options[:path] ? strip_leading_slash(options[:path]) : @name
      @segments = []
    end

    private

    def strip_leading_slash(string)
      (result = string.gsub(/\A\//, '')) != '' ? result : nil
    end
  end
end
