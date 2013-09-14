module Vendorificator
  class Segment::Overlay < Segment
    attr_reader :overlay, :segments

    def initialize(options)
      @overlay = ::Vendorificator::Overlay.new(options[:path])
      @segments = []
      super
    end

    def name
      "Overlay \"#{@overlay.path}\""
    end

    def branch_name
      _join config[:branch_prefix], 'overlay', overlay.path, 'layer', group, name
    end

    def compute_dependencies!
      each_segment { |seg| seg.compute_dependencies! }
    end

    # Public: Goes through all the Vendor instances and runs the block
    #
    # segments - An Array of vendor segments to yield the block for.
    #
    # Returns nothing.
    def each_segment(*segments)
      # We don't use @segments.each here, because Vendor#run! is
      # explicitly allowed to append to instantiate new dependencies, and #each
      # fails to catch up on some Ruby implementations.
      i = 0
      while true
        break if i >= @segments.length
        seg = @segments[i]
        yield seg if segments.empty? || seg.included_in_list?(segments)
        i += 1
      end
    end

    private

    def path
      @vendor.args[:path] || _join(overlay.path, group, name)
    end

  end
end

