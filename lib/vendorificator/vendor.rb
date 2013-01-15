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

    def work_subdir
      File.join(Vendorificator::Config[:basedir], path||name)
    end

    def work_dir
      File.join(Vendorificator::Config[:root_dir], work_subdir)
    end

    def status
      repo = Vendorificator::Config.repo
      return :new unless repo.branches.find { |b| b.name == branch_name }
      return :outdated unless repo.tags.find { |t| t.name == conjure_tag_name }
      return :up_to_date
    end

    def needed?
      return self.status != :up_to_date
    end

    def run!
      repo = Vendorificator::Config.repo
      orig_head = repo.head

      unless needed?
        shell.say_status 'up to date', work_subdir, :blue
        return
      end

      # We want to be in repository's root now, as we will need to
      # remove stuff and don't want to have removed directory as cwd.
      Dir::chdir repo.working_dir do
        # If our branch exists, check it out; otherwise, create a new
        # orphaned branch.
        if repo.get_head(branch_name)
          repo.git.checkout( {}, branch_name )
        else
          repo.git.checkout( { :orphan => true }, branch_name )
        end

        # Prepare a nice, clean place for work.
        repo.git.rm( { :r => true, :f => true }, '.')
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

        # Merge back to the original branch
        repo.git.checkout( {}, orig_head.name )
        repo.git.pull( {}, '.', branch_name )
      end
    ensure
      # If conjuring failed, we should make sure we're back on original branch
      repo.git.checkout( {}, orig_head.name ) if defined?(orig_head) rescue nil
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

    install!
  end
end
