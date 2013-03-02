require 'fileutils'

require 'thor/shell/basic'

require 'vendorificator/config'

module Vendorificator
  class Vendor

    class << self
      attr_accessor :category, :method_name

      # Define a method on Vendorificator::Config to add the
      # vendor module to the module definition list.
      def install!
        @method_name ||= self.name.split('::').last.downcase.to_sym
        _cls = self # for self is obscured in define_method block's body
        ( class << Vendorificator::Config ; self ; end ).
            send(:define_method, @method_name ) do |name, *args, &block|
          _cls.new(self.environment, name.to_s, *args, &block)
        end
      end

      def arg_reader(*names)
        names.each do |name|
          define_method(name) do
            args[name]
          end
        end
      end

      def [](*key)
        return key.map { |k| self[k] }.flatten if key.length > 1

        key = key.first

        if key.is_a?(Fixnum)
          self.instances[key]
        else
          instances.select { |i| i === key }
        end
      end

      def each(*modules)
        modpaths = modules.map { |m| File.expand_path(m) }

        # We don't use instances.each here, because Vendor#run! is
        # explicitly allowed to append to instantiate new
        # dependencies, and #each fails to catch up on some Ruby
        # implementations.
        i = 0
        while true
          break if i >= instances.length
          mod = instances[i]
          yield mod if modules.empty? ||
            modules.include?(mod.name) ||
            modpaths.include?(mod.work_dir)
          i += 1
        end
      end

      def instances
        Vendorificator::Vendor.instance_eval { @instances ||= [] }
      end

      def compute_dependencies!
        self.instances.each(&:compute_dependencies!)
      end
    end

    attr_reader :environment, :name, :args, :block
    arg_reader :version

    def initialize(environment, name, args={}, &block)
      @environment = environment
      @category = args.delete(:category) if args.key?(:category)

      @name = name
      @args = args
      @block = block

      self.class.instances << self
    end

    def ===(other)
      other === self.name or File.expand_path(other.to_s) == self.work_dir
    end

    def path
      args[:path] || _join(category, name)
    end

    def shell
      @shell ||=
        environment.config[:shell] || Thor::Shell::Basic.new
    end

    def category
      if instance_variable_defined?(:@category)
        @category
      else
        self.class.category
      end
    end

    def branch_name
      _join(environment.config[:branch_prefix], category, name)
    end

    def to_s
      _join(name, version)
    end

    def inspect
      "#<#{self.class} #{self}>"
    end

    def work_subdir
      _join(environment.config[:basedir], path)
    end

    def work_dir
      _join(environment.config[:root_dir], work_subdir)
    end

    def head
      environment.git.capturing.rev_parse({:verify => true}, "refs/heads/#{branch_name}").strip
    rescue MiniGit::GitError
      nil
    end

    def tagged_sha1
      @tagged_sha1 ||= environment.git.capturing.rev_parse({:verify => true}, "refs/tags/#{tag_name}^{commit}").strip
    rescue MiniGit::GitError
      nil
    end

    def merged
      unless @_has_merged
        if ( head = self.head )
          merged = environment.git.capturing.merge_base(head, 'HEAD').strip
          @merged = merged unless merged.empty?
        end
        @_has_merged = true
      end
      @merged
    end

    def merged_tag
      unless @_has_merged_tag
        if merged
          tag = environment.git.capturing.describe( {
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

    def version
      @args[:version] || (!environment.config[:use_upstream_version] && merged_version) || upstream_version
    end

    def upstream_version
      # To be overriden
    end

    def updatable?
      return nil if self.status == :up_to_date
      return false if !head
      return false if head && merged == head
      environment.git.describe({:abbrev => 0, :always => true}, branch_name)
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
      orig_branch = environment.current_branch

      # We want to be in repository's root now, as we may need to
      # remove stuff and don't want to have removed directory as cwd.
      Dir::chdir environment.git.git_work_tree do
        # If our branch exists, check it out; otherwise, create a new
        # orphaned branch.
        if self.head
          environment.git.checkout branch_name
          environment.git.rm( { :r => true, :f => true, :q => true, :ignore_unmatch => true }, '.') if options[:clean]
        else
          environment.git.checkout( { :orphan => true }, branch_name )
          environment.git.rm( { :r => true, :f => true, :q => true, :ignore_unmatch => true }, '.')
        end
      end

      yield
    ensure
      # We should try to ensure we're back on original branch
      environment.git.checkout orig_branch if defined?(orig_branch) rescue nil
    end

    def run!
      case status

      when :up_to_date
        shell.say_status 'up to date', self.to_s

      when :unpulled, :unmerged
        shell.say_status 'merging', self.to_s, :yellow
        environment.git.merge({}, tagged_sha1)
        compute_dependencies!

      when :outdated, :new
        shell.say_status 'fetching', self.to_s, :yellow
        begin
          shell.padding += 1
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


            # Commit and tag the conjured module
            environment.git.add work_dir
            environment.git.commit :m => conjure_commit_message
            environment.git.tag( { :a => true, :m => tag_message }, tag_name )
            shell.say_status :tag, tag_name
          end
          # Merge back to the original branch
          environment.git.merge( {}, branch_name )
          compute_dependencies!
        ensure
          shell.padding -= 1
        end

      else
        say_status self.status, "I'm unsure what to do.", :red
      end
    end

    def tag_name_base
      _join('vendor', category, name)
    end

    def tag_name
      _join(tag_name_base, version)
    end

    def conjure_commit_message
      "Conjured vendor module #{name} version #{version}"
    end

    def tag_message
      conjure_commit_message
    end

    def conjure!
      block.call(self) if block
    end

    def compute_dependencies! ; end

    private

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

    install!
  end
end
