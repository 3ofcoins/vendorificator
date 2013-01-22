require 'fileutils'

require 'thor/shell/basic'

require 'vendorificator/config'

module Vendorificator
  class Vendor

    class << self
      # Define a method on Vendorificator::Config to add the
      # vendor module to the module definition list.
      def install!
        @method_name ||= self.name.split('::').last.downcase.to_sym
        _cls = self # for self is obscured in define_method block's body
        ( class << Vendorificator::Config ; self ; end ).
            send(:define_method, @method_name ) do |name, *args, &block|
          self[:modules] << _cls.new(name.to_s, *args, &block)
        end
      end

      def arg_reader(*names)
        names.each do |name|
          define_method(name) do
            args[name]
          end
        end
      end
    end

    attr_reader :config, :name, :args, :block
    arg_reader :version, :path

    def initialize(name, args={}, &block)
      @name = name
      @args = args
      @block = block
    end

    def shell
      @shell ||=
        Vendorificator::Config[:shell] || Thor::Shell::Basic.new
    end

    def branch_name
      "#{Vendorificator::Config[:branch_prefix]}#{name}"
    end

    def to_s
      rv = "#{name}"
      rv << "/#{version}" if version
    end

    def inspect
      "#<#{self.class} #{self}>"
    end

    def work_subdir
      File.join(Vendorificator::Config[:basedir], path||name)
    end

    def work_dir
      File.join(Vendorificator::Config[:root_dir], work_subdir)
    end

    def head
      repo.get_head(branch_name)
    end

    def tag
      repo.tags.find { |t| t.name == conjure_tag_name }
    end

    def merged
      rv = repo.git.merge_base({}, head.commit.sha, repo.head.commit.sha).strip
      rv unless rv.empty?
    end

    def updatable?
      return nil if self.status == 'up_to_date'
      return false if merged == head.commit.sha
      head_tag = repo.tags.find { |t| t.name == repo.recent_tag_name(head.name) }
      return head_tag || true
    end

    def status
      # If there's no branch yet, it's a completely new module
      return :new unless head

      # If there's a branch but no tag, it's a known module that's not
      # been updated for the new definition yet.
      return :outdated unless tag

      # Well, this is awkward: branch is in config and exists, but is
      # not merged into current branch at all.
      return :unmerged unless merged

      # Merge base is tagged with our tag. We're good.
      return :up_to_date if tag.commit.sha == merged

      return :unpulled if repo.fast_forwardable?(tag.commit.sha, merged)

      return :unknown
    end

    def needed?
      return self.status != :up_to_date
    end

    def in_branch(options={}, &block)
      orig_head = repo.head

      # We want to be in repository's root now, as we may need to
      # remove stuff and don't want to have removed directory as cwd.
      Dir::chdir repo.working_dir do
        # If our branch exists, check it out; otherwise, create a new
        # orphaned branch.
        if self.head
          repo.git.checkout( {}, branch_name )
          repo.git.rm( { :r => true, :f => true }, '.') if options[:clean]
        else
          repo.git.checkout( { :orphan => true }, branch_name )
          repo.git.rm( { :r => true, :f => true }, '.')
        end
      end

      yield
    ensure
      # We should make sure we're back on original branch
      repo.git.checkout( {}, orig_head.name ) if defined?(orig_head) rescue nil
    end

    def run!
      case status

      when :up_to_date
        shell.say_status 'up to date', self.to_s

      when :unpulled, :unmerged
        shell.say_status 'merging', self.to_s, :yellow
        repo.git.merge({}, tag.name)

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
            end

            # Commit and tag the conjured module
            repo.add(work_dir)
            repo.commit_index(conjure_commit_message)
            repo.git.tag( { :a => true, :m => conjure_tag_message }, conjure_tag_name )
            shell.say_status :tag, conjure_tag_name
          end
          # Merge back to the original branch
          repo.git.merge( {}, branch_name )
        ensure
          shell.padding -= 1
        end

      else
        say_status self.status, "I'm unsure what to do.", :red
      end
    end

    def conjure_commit_message
      "Conjured vendor module #{name} version #{version}"
    end

    def conjure_tag_name
      "vendor/#{name}/#{version}"
    end

    def conjure_tag_message
      conjure_commit_message
    end

    def conjure!
      block.call(self) if block
    end

    def dependencies ; [] ; end

    private

    def conf
      Vendorificator::Config
    end

    def repo
      Vendorificator::Config.repo
    end

    install!
  end
end
