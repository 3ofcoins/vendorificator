require 'digest'
require 'open-uri'
require 'tempfile'
require 'uri'

require 'escape'

require 'vendorificator/vendor'

module Vendorificator
  class Vendor::Archive < Vendor
    arg_reader :url, :strip_root, :type, :checksum, :filename, :basename, :extname, :unpack
    attr_reader :conjured_checksum, :conjured_filesize

    def conjure!
      shell.say_status :download, url
      archive = download_file
      shell.say_status :unpack, filename
      unpack_file archive
      add_archive_metadata
      super
    ensure
      if archive
        archive.close
        archive.unlink
      end
    end

    def upstream_version
      filename
    end

    def conjure_commit_message
      rv = "Conjured archive #{name} from #{filename}\nOrigin: #{url}\nChecksum: #{conjured_checksum}\n"
      rv << "Version: #{version}\n" if version
      rv
    end

    private

    def download_file
      archive = Tempfile.new([basename, extname])
      archive.write( open(url).read )
      @conjured_filesize = archive.size
      archive.close
      @conjured_checksum = Digest::SHA256.file(archive.path).hexdigest
      raise RuntimeError, "Checksum error" if checksum && checksum != conjured_checksum

      archive
    end

    def unpack_file(archive)
      system "#{unpack} #{Escape.shell_single_word archive.path}"
      if Dir.entries('.').length == 3 && !args[:no_strip_root]
        root = (Dir.entries('.') - %w(.. .)).first
        root_entries = Dir.entries(root) - %w(.. .)
        while root_entries.include?(root)
          FileUtils::mv root, root+"~"
          root << "~"
        end
        FileUtils::mv root_entries.map { |e| File.join(root, e) }, '.'
        FileUtils::rmdir root
      end
    end

    def add_archive_metadata
      @metadata[:archive_checksum] = conjured_checksum
      @metadata[:archive_filesize] = conjured_filesize
      @metadata[:archive_url] = url
    end

    def parse_initialize_args(args = {})
      no_url_given = !args[:url]

      args[:url] ||= @name
      args[:filename] ||= URI::parse(args[:url]).path.split('/').last

      case args[:filename]
      when /\.(tar\.|t)gz$/
        args[:type] ||= :targz
        args[:unpack] ||= 'tar -xzf'
      when /\.tar\.bz2$/
        args[:type] ||= :tarbz2
        args[:unpack] ||= 'tar -xjf'
      when /\.zip$/
        args[:type] ||= :zip
        args[:unpack] ||= 'unzip'
      when /\.[^\.][^\.]?[^\.]?[^\.]?$/
        args[:type] ||=
          begin
            unless args[:unpack]
              raise RuntimeError,
              "Unknown file type #{$&.inspect}, please provide :unpack argument"
            end
            $&
          end
      else
        args[:basename] ||= args[:filename]
        args[:extname] ||= ''
        unless args[:unpack] || [:targz, :tarbz2, :zip].include?(args[:type])
          raise RuntimeError, "Unknown file type for #{args[:filename].inspect}, please provide :unpack or :type argument"
        end
      end
      args[:basename] ||= $`
      args[:extname] ||= $&

      @name = args[:basename] if no_url_given

      super args
    end
  end

  class Config
    register_module :archive, Vendor::Archive
  end
end
