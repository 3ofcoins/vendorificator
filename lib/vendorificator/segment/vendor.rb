module Vendorificator
  class Segment::Vendor < Segment
    attr_reader :overlay, :vendor

    def initialize(options)
      @vendor = options.delete(:vendor)
      @overlay = options.delete(:overlay)
      super
    end

    def name
      @vendor.name
    end

    def group
      @vendor.group
    end

    def version
      @vendor.version
    end

    def branch_name
      if overlay
        _join overlay.branch_name, group, name
      else
        _join config[:branch_prefix], group, name
      end
    end

    def compute_dependencies!
      @vendor.compute_dependencies!
    end

    # Public: Conjures the vendor module without merging back.
    #
    # options - available options: :metadata - Hash with metadata information
    #
    # Returns nothing.
    def conjure(options = {})
      @vendor.before_conjure!
      in_branch(branch_name, clean: true) do |tmpgit|
        begin
          @git = tmpgit
          @vendor.git = tmpgit
          in_work_dir do
            @vendor.conjure!

            subdir = @vendor.args[:subdirectory]
            make_subdir_root subdir if subdir && !subdir.empty?
          end
          commit_and_annotate(options[:metadata] || {})
        ensure
          @git = nil
          @vendor.git = nil
        end
      end
    end

    # Public: Merges back to the original branch (usually master).
    #
    # commit - git ref/branch to merge, defaults to segment branch
    #
    # Returns nothing.
    def merge_back(commit = branch_name)
      git.capturing.merge({no_edit: true, no_ff: true}, commit)
      @vendor.postprocess! if @vendor.respond_to? :postprocess!
      @vendor.compute_dependencies!
    end

    private

    def update(options = {})
      shell.padding += 1
      conjure options
      merge_back
    ensure
      shell.padding -= 1
    end

    def environment
      @vendor.environment
    end

    def path
      if overlay
        _join overlay.path, group, name
      else
        @vendor.args[:path] || _join(group, name)
      end
    end

    def work_subdir
      if overlay
        _join overlay.path
      else
        _join config[:basedir], path
      end
    end

  end
end
