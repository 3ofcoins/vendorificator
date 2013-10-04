module Vendorificator
  class Segment::Overlay < Segment
    attr_reader :overlay, :segments, :environment

    def initialize(options)
      @overlay = ::Vendorificator::Overlay.new(options[:overlay_opts])
      @environment = options[:environment]
      @segments = []
      super
    end

    def name
      "Overlay \"#{overlay.path}\""
    end

    def base_branch_name
      _join config[:branch_prefix], 'overlay', (overlay.name || overlay.path)
    end

    def branch_name
      _join base_branch_name, 'layer'
    end

    def merge_branch_name
      _join base_branch_name, 'merged'
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

    def merge_back
      in_branch merge_branch_name do |git|
        each_segment do |seg|
          git.capturing.merge({:no_edit => true, :no_ff => true}, seg.branch_name)
        end
      end
      git.capturing.merge({:no_edit => true, :no_ff => true}, merge_branch_name)

      each_segment do |seg|
        seg.vendor.postprocess! if seg.vendor.respond_to? :postprocess!
        seg.vendor.compute_dependencies!
      end
    end

    def update(options = {})
      shell.padding += 1
      each_segment do |seg|
        seg.conjure options
      end

      merge_back
    ensure
      shell.padding -= 1
    end

    def work_subdir
      _join path
    end

    def in_branch(branch = branch_name, options = {}, &block)
      Dir.mktmpdir do |tmpdir|
        tmpgit = create_temp_git_repo(branch, options, tmpdir)
        fetch_repo_data tmpgit
        repo_cleanup tmpgit if options[:clean] || !branch_exists?

        Dir.chdir(tmpdir){ yield tmpgit }

        propagate_repo_data_to_original branch, tmpdir
      end
    end

    def fetch_repo_data(tmpgit)
      super
      each_segment do |seg|
        tmpgit.fetch git.git_dir,
          "refs/heads/#{seg.branch_name}:refs/heads/#{seg.branch_name}"
      end
    end

    def create_temp_git_repo(branch, options, dir)
      tmpgit = super
      unless branch_exists? branch
        tmpgit.capturing.commit allow_empty: true, message: 'Empty init'
      end

      tmpgit
    end

  end
end

