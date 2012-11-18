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
        Vendorificator::Config.define_singleton_method(@method_name) do |name, *args|
          self[:modules][name.to_s] = _cls.new(name.to_s, *args)
        end
      end
    end

    def self.arg_reader(*names)
      names.each do |name|
        define_method(name) do
          args[name]
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
      "#{config.branch_prefix}#{name}"
    end

    def work_dir
      File.join(config.basedir, name)
    end

    def run!
      # If our branch exists, check it out; otherwise, create a new
      # orphaned branch.
      begin
        git.checkout(branch_name)
      rescue Git::GitExecuteError
        git.checkout( { :orphan => true }, branch_name )
      end

      # Prepare a nice, clean place for work.
      git.rm( { :r => true, :f => true }, '.')
      
    end

    install!
  end

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
      when /\.([^\.]{1-4})$/
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
