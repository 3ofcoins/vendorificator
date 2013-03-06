require 'fileutils'
require 'vendorificator/vendor'

class Vendorificator::Vendor::Git < Vendorificator::Vendor
  arg_reader :repository, :revision, :tag, :branch
  attr_reader :git, :conjured_revision

  def initialize(environment, name, args={}, &block)
    args[:version] ||= args[:tag] if args[:tag]
    if [:revision, :tag, :branch].select { |key| args.key?(key) }.count > 1
      raise ArgumentError, "You can provide only one of: :revision, :tag, :branch"
    end

    unless args.include?(:repository)
      args[:repository] = name
      name = name.split('/').last.sub(/\.git$/, '')
    end
    super(environment, name, args, &block)
  end

  def conjure!
    shell.say_status :clone, repository
    MiniGit.git :clone, repository, '.'
    @git = MiniGit.new('.')

    if tag||revision
      git.checkout({:b => 'vendorified'}, tag||revision)
    elsif branch
      git.checkout({:b => 'vendorified'}, "origin/#{branch}")
    end

    super

    @conjured_revision = git.capturing.rev_parse('HEAD').strip
    FileUtils::rm_rf '.git'
  end

  def upstream_version
    tag || conjured_revision
  end

  def conjure_commit_message
    rv = "Conjured git module #{name} "
    rv << "version #{version} " if version
    rv << "from tag #{tag} " if tag
    rv << "from branch #{branch} " if branch
    rv << "at revision #{conjured_revision}"
    rv
  end

end
