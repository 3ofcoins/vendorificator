require 'uri'

module Vendorificator
  class Vendor
    def self.arg_reader(*names)
      names.each do |name|
        define_method(name) do
          args[name]
        end
      end
    end

    attr_reader :config, :name, :args, :block
    arg_reader :version, :path

    def initialize(config, name, args={}, &block)
      @config = config
      @name = name
      @args = args
      @block = block
    end
  end

  class Archive < Vendor
    arg_reader :url, :strip_root, :type, :checksum

    def initialize(config, name, args={}, &block)
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

      super(config, name, args, &block)
    end
  end

  class Git < Vendor
    arg_reader :repository, :revision, :branch
  end
end
