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

    attr_reader :environment, :name, :args, :block, :unit
    attr_accessor :git
    arg_reader :version

    def initialize(environment, name, args = {}, &block)
      @environment = environment
      @name = name
      @block = block
      @metadata = {
        :module_name => @name,
        :unparsed_args => args.clone
      }
      @metadata[:parsed_args] = @args = parse_initialize_args(args)
      @metadata[:module_annotations] = @args[:annotate] if @args[:annotate]

      @unit = if config.overlay_instance
                Unit::Overlay.new(vendor: self)
              else
                Unit::Vendor.new(vendor: self)
              end
      @environment.units << @unit
    end

    def ===(other)
      other === self.name or File.expand_path(other.to_s) == self.work_dir
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
      @unit.branch_name
    end

    def inspect
      "#<#{self.class} #{self}>"
    end

    def work_dir
      @unit.work_dir
    end

    def head
      @unit.head
    end

    def tag_name
      _join(tag_name_base, version)
    end

    def version
      @args[:version] || (!config[:use_upstream_version] && merged_version) || upstream_version
    end

    def upstream_version
      # To be overriden
    end

    def updatable?
      @unit.updatable?
    end

    def status
      @unit.status
    end

    def needed?
      return self.status != :up_to_date
    end

    def conjure!
      block.call(self) if block
    end

    # Hook points
    def git_add_extra_paths ; [] ; end
    def before_conjure! ; end
    def compute_dependencies! ; end

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
        module_list.include?(merged_base) ||
        module_list.include?(branch_name)
    end

    def merged_version
      merged_tag && merged_tag[(1 + tag_name_base.length)..-1]
    end

    # Public: Merges all the data we use for the commit note.
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

    def conjure_commit_message
      "Conjured vendor module #{name} version #{version}"
    end

    def tag_message
      conjure_commit_message
    end

    private

    def parse_initialize_args(args = {})
      @group = args.delete(:group) if args.key?(:group)
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

    def git
      @git || environment.git
    end

    def config
      environment.config
    end

    def _join(*parts)
      parts.compact.map(&:to_s).join('/')
    end

    def merged_base
      return @merged_base if defined? @merged_base
      base = git.capturing.merge_base(head, 'HEAD').strip
      @merged_base = base.empty? ? nil : base
    rescue MiniGit::GitError
      @merged_base = nil
    end

    def merged?
      !merged_base.nil?
    end

    def merged_tag
      return @merged_tag if defined? @merged_tag
      @merged_tag = if merged?
          tag = git.capturing.describe( {
              :exact_match => true,
              :match => _join(tag_name_base, '*') },
            merged_base).strip
          tag.empty? ? nil : tag
        else
          nil
        end
    end
  end

  Config.register_module :vendor, Vendor
end
