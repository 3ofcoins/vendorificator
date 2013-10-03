module Vendorificator
  class Overlay
    attr_reader :path, :segments

    def initialize(options = {})
      @name = options[:name]
      if options[:path]
        @path = options[:path]
      else
        @path = @name.clone
      end

      # Clears leading '/' from the path.
      @path = (adj_path = @path.gsub(/\A\//, '')) != '' ? adj_path : nil
      @segments = []
    end

  end
end
