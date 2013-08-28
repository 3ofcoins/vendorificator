require 'fileutils'
require 'tmpdir'
require 'thor/shell/basic'
require 'yaml'
require 'vendorificator/config'

module Vendorificator
  class Vendor

    class << self
      attr_accessor :group, :method_name

      def arg_reader(*names)
        names.each do |name|
          define_method(name) do
            args[name]
          end
        end
      end
    end

    attr_reader :environment, :name, :args, :block, :overlay
    arg_reader :version

    def initialize(environment, name, args = {}, &block)
      @environment = environment
      @overlay = config.overlay_instance
      @name = name
      @block = block
      @metadata = {
        :module_name => @name,
        :unparsed_args => args.clone
      }
      @metadata[:parsed_args] = @args = parse_initialize_args(args)
      @metadata[:module_annotations] = @args[:annotate] if @args[:annotate]

      @environment.vendor_instances << self
    end

    def ===(other)
      other === self.name or File.expand_path(other.to_s) == self.work_dir
    end

    def path
      args[:path] || if overlay
          _join('overlay', overlay.path, 'layer', group, name)
        else
          _join(group, name)
        end
    end

    def shell
      @environment.shell
    end

    def say(verb_level= :default, &block)
      output = yield
      @environment.say verb_level, output
    end

    def say_status(*args, &block)
      @environment.say_status(*args, &block)
    end

    def group
      defined?(@group) ? @group : self.class.group
    end

    def branch_name
      _join(config[:branch_prefix], group, name)
    end

    def to_s
      _join(name, version)
    end

    def inspect
      "#<#{self.class} #{self}>"
    end

    def work_subdir
      _join(config[:basedir], path)
    end

    def work_dir
      _join(git.git_work_tree, environment.relative_root_dir, work_subdir)
    end

    def head
      git.capturing.rev_parse({:verify => true, :quiet => true}, "refs/heads/#{branch_name}").strip
    rescue MiniGit::GitError
      nil
    end

    def tag_name
      _join(tag_name_base, version)
    end

    def merged
      unless @_has_merged
        if ( head = self.head )
          merged = git.capturing.merge_base(head, 'HEAD').strip
          @merged = merged unless merged.empty?
        end
        @_has_merged = true
      end
      @merged
    rescue MiniGit::GitError
      @_has_merged = true
      @merged = nil
    end

    def merged_tag
      unless @_has_merged_tag
        if merged
          tag = git.capturing.describe( {
              :exact_match => true,
              :match => _join(tag_name_base, '*') },
            merged).strip
          @merged_tag = tag unless tag.empty?
        end
        @_has_merged_tag = true
      end
      @merged_tag
    end

    def merged_version
      merged_tag && merged_tag[(1+tag_name_base.length)..-1]
    end

    # Public: Get git vendor notes of the merged commit.
    #
    # Returns the Hash of git vendor notes.
    def merged_notes
      Commit.new(merged, git).notes?
    end

    def version
      @args[:version] || (!config[:use_upstream_version] && merged_version) || upstream_version
    end

    def upstream_version
      # To be overriden
    end

    def updatable?
      return nil if self.status == :up_to_date
      return false if !head
      return false if head && merged == head
      git.describe({:abbrev => 0, :always => true}, branch_name)
    end

    def status
      # If there's no branch yet, it's a completely new module
      return :new unless head

      # If there's a branch but no tag, it's a known module that's not
      # been updated for the new definition yet.
      return :outdated unless tagged_sha1

      # Well, this is awkward: branch is in config and exists, but is
      # not merged into current branch at all.
      return :unmerged unless merged

      # Merge base is tagged with our tag. We're good.
      return :up_to_date if tagged_sha1 == merged

      return :unpulled if environment.fast_forwardable?(tagged_sha1, merged)

      return :unknown
    end

    def needed?
      return self.status != :up_to_date
    end

    def in_branch(options={}, &block)
      branch_exists = !!self.head
      notes_exist = begin
                      git.capturing.rev_parse({verify: true, quiet: true}, 'refs/notes/vendor')
                    rescue MiniGit::GitError
                      nil
                    end
      Dir.mktmpdir("vendor-#{group}-#{name}") do |tmpdir|
        clone_opts = {:shared => true, :no_checkout => true}
        clone_opts[:branch] = branch_name if branch_exists
        say { MiniGit::Capturing.git(:clone, clone_opts, git.git_dir, tmpdir) }
        tmpgit = MiniGit.new(tmpdir)
        #TODO: Silence/handle the stderr output from git-checkout
        tmpgit.capturing.checkout({orphan: true}, branch_name) unless branch_exists
        tmpgit.fetch(git.git_dir, "refs/notes/vendor:refs/notes/vendor") if notes_exist
        if options[:clean] || !branch_exists
          tmpgit.rm({ :r => true, :f => true, :q => true, :ignore_unmatch => true }, '.')
        end

        begin
          @git = tmpgit
          Dir.chdir(tmpdir) do
            yield
          end
        ensure
          @git = nil
        end

        #TODO: Silence/handle the stderr output from git-fetch
        git.fetch(tmpdir)
        git.fetch({tags: true}, tmpdir)
        git.fetch(tmpdir,
          "refs/heads/#{branch_name}:refs/heads/#{branch_name}",
          "refs/notes/vendor:refs/notes/vendor")
      end
    end

    def run!(options = {})
      case status

      when :up_to_date
        say_status :default, 'up to date', self.to_s

      when :unpulled, :unmerged
        say_status :default, 'merging', self.to_s, :yellow
        git.merge({:no_edit => true, :no_ff => true}, tagged_sha1)
        postprocess! if self.respond_to? :postprocess!
        compute_dependencies!

      when :outdated, :new
        say_status :default, 'fetching', self.to_s, :yellow
        begin
          shell.padding += 1
          before_conjure!
          in_branch(:clean => true) do
            FileUtils::mkdir_p work_dir

            # Actually fill the directory with the wanted content
            Dir::chdir work_dir do
              begin
                shell.padding += 1
                self.conjure!
              ensure
                shell.padding -= 1
              end

              subdir = args[:subdirectory]
              make_subdir_root subdir if subdir && !subdir.empty?
            end

            commit_and_annotate(options[:metadata])
          end
          # Merge back to the original branch
          git.capturing.merge( {:no_edit => true, :no_ff => true}, branch_name )
          postprocess! if self.respond_to? :postprocess!
          compute_dependencies!
        ensure
          shell.padding -= 1
        end

      else
        say_status :quiet, self.status, "I'm unsure what to do.", :red
      end
    end

    def conjure!
      block.call(self) if block
    end

    # Hook points
    def git_add_extra_paths ; [] ; end
    def before_conjure! ; end
    def compute_dependencies! ; end

    def pushable_refs
      created_tags.unshift("refs/heads/#{branch_name}")
    end

    def metadata
      default = {
        :module_version => version,
        :module_group => @group,
      }
      default.merge @metadata
    end

    def included_in_list?(module_list)
      modpaths = module_list.map { |m| File.expand_path(m) }

      module_list.include?(name) ||
        module_list.include?("#{group}/#{name}") ||
        modpaths.include?(File.expand_path(work_dir)) ||
        module_list.include?(merged) ||
        module_list.include?(branch_name)
    end

    private

    def parse_initialize_args(args = {})
      @group = args.delete(:group) if args.key?(:group)
      @overlay = args.delete(:overlay) if args.key?(:overlay)
      if args.key?(:category)
        @group ||= args.delete(:category)
        say_status :default, 'DEPRECATED', 'Using :category option is deprecated and will be removed in future versions. Use :group instead.'
      end

      unless (hooks = Array(args.delete(:hooks))).empty?
        hooks.each do |hook|
          hook_module = hook.is_a?(Module) ? hook : ::Vendorificator::Hooks.const_get(hook)
          klass = class << self; self; end;
          klass.send :include, hook_module
        end
      end

      args
    end

    def tag_name_base
      _join('vendor', group, name)
    end

    def conjure_commit_message
      "Conjured vendor module #{name} version #{version}"
    end

    def tag_message
      conjure_commit_message
    end

    def tagged_sha1
      @tagged_sha1 ||= git.capturing.rev_parse(
        {:verify => true, :quiet => true}, "refs/tags/#{tag_name}^{commit}"
      ).strip
    rescue MiniGit::GitError
      nil
    end

    def created_tags
      git.capturing.show_ref.lines.map{ |line| line.split(' ')[1] }.
        select{ |ref| ref =~ /\Arefs\/tags\/#{tag_name_base}\// }
    end

    def git
      @git || environment.git
    end

    def config
      environment.config
    end

    def _join(*parts)
      parts.compact.map(&:to_s).join('/')
    end

    def make_subdir_root(subdir_path)
      curdir = Pathname.pwd
      tmpdir = Pathname.pwd.dirname.join("#{Pathname.pwd.basename}.tmp")
      subdir = Pathname.pwd.join(subdir_path)

      Dir.chdir('..')

      subdir.rename(tmpdir.to_s)
      curdir.rmtree
      tmpdir.rename(curdir.to_s)
    ensure
      Dir.chdir(curdir.to_s) if curdir.exist?
    end

    # Private: Commits and annotates the conjured module.
    #
    # environment_metadata - Hash with environment metadata where vendor was run
    #
    # Returns nothing.
    def commit_and_annotate(environment_metadata = {})
      git.capturing.add work_dir, *git_add_extra_paths
      git.capturing.commit :m => conjure_commit_message
      git.capturing.notes({:ref => 'vendor'}, 'add', {:m => conjure_note(environment_metadata)}, 'HEAD')
      git.capturing.tag( { :a => true, :m => tag_message }, tag_name )
      say_status :default, :tag, tag_name
    end

    # Private: Merges all the data we use for the commit note.
    #
    # environment_metadata - Hash with environment metadata where vendor was run
    #
    # Returns: The note in the YAML format.
    def conjure_note(environment_metadata = {})
      config.metadata.
        merge(environment_metadata).
        merge(metadata).
        to_yaml
    end
  end

  Config.register_module :vendor, Vendor
end
