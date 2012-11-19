require 'fileutils'
require 'uri'

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

    def branch_name
      "#{Vendorificator::Config[:branch_prefix]}#{name}"
    end

    def work_dir
      File.join(Vendorificator::Config[:root_dir], Vendorificator::Config[:basedir], path||name)
    end

    def run!
      repo = Vendorificator::Config.repo

      # We want to be in repository's root now, as we will need to
      # remove stuff and don't want to have removed directory as cwd.
      Dir::chdir repo.working_dir do
        orig_head = repo.head

        # If our branch exists, check it out; otherwise, create a new
        # orphaned branch.
        if repo.heads.find { |head| head.name == branch_name }
          repo.git.checkout( {}, branch_name )
        else
          repo.git.checkout( { :orphan => true }, branch_name )
        end

        # Prepare a nice, clean place for work.
        repo.git.rm( { :r => true, :f => true }, '.')
        FileUtils::mkdir_p work_dir

        # Actually fill the directory with the wanted content
        Dir::chdir work_dir do
          self.conjure!
        end

        # Commit and tag the conjured module
        repo.add(work_dir)
        repo.commit_index(conjure_commit_message)
        repo.git.tag( { :a => true, :m => conjure_tag_message }, conjure_tag_name )

        # Merge back to the original branch
        repo.git.checkout( {}, orig_head.name )
        repo.git.pull( {}, '.', branch_name )
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

    install!

    class Archive < Vendor
      arg_reader :url, :strip_root, :type, :checksum

      def initialize(name, args={}, &block)
        no_url_given = !args[:url]

        args[:url] ||= name
        args[:filename] ||= URI::parse(args[:url]).path.split('/').last

        case args[:filename]
        when /\.(tar\.|t)gz$/
          args[:type] ||= :targz
        when /\.tar\.bz2$/
          args[:type] ||= :tarbz2
        when /\.zip$/
          args[:type] ||= :zip
        when /\.([^\.][^\.]?[^\.]?[^\.]?)$/
          args[:type] ||=
            begin
              unless args[:unpack]
                raise RuntimeError,
                "Unknown file type #{$1.inspect}, please provide :unpack argument"
              end
              $1
            end
        else
          args[:basename] ||= args[:filename]
          args[:extension] ||= ''
          unless args[:unpack] || [:targz, :tarbz2, :zip].include?(args[:type])
            raise RuntimeError, "Unknown file type for #{args[:filename].inspect}, please provide :unpack or :type argument"
          end
        end
        args[:basename] ||= $`
        args[:extension] ||= $&

        name = args[:basename] if no_url_given

        super(name, args, &block)
      end

      install!
    end

    class Git < Vendor
      arg_reader :repository, :revision, :branch

      install!
    end
  end
end
