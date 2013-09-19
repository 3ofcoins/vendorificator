module Vendorificator
  class Segment::Overlay < Segment
    attr_reader :overlay, :segments, :environment

    def initialize(options)
      @overlay = ::Vendorificator::Overlay.new(options[:path])
      @environment = options[:environment]
      @segments = []
      super
    end

    def name
      "Overlay \"#{overlay.path}\""
    end

    def branch_name
      _join config[:branch_prefix], 'overlay', overlay.path, 'layer'
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

    def group
      nil
    end

    def version
      nil
    end

    def path
      _join overlay.path
    end

    private

    def merge_back(commit = branch_name)
      git.capturing.merge({:no_edit => true, :no_ff => true}, commit)
      each_segment do |seg|
        seg.vendor.postprocess! if seg.vendor.respond_to? :postprocess!
        seg.vendor.compute_dependencies!
      end
    end

    def update(options)
      each_segment { |seg| seg.send :update, options }
    end

  end
end

