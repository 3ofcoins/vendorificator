require 'fileutils'

require 'grit'

require 'vendorificator/vendor'

class Vendorificator::Vendor::Git < Vendorificator::Vendor
  arg_reader :repository, :revision, :branch
  attr_reader :repo, :conjured_revision

  def initialize(name, args={}, &block)
    unless args.include?(:repository)
      args[:repository] = name
      name = name.split('/').last.sub(/\.git$/, '')
    end
    super(name, args, &block)
  end

  def conjure!
    Grit::Git.new('.').clone({}, repository, '.')
    @repo = Grit::Repo.new('.')
    super
    @conjured_revision = repo.head.commit.id
    FileUtils::rm_rf '.git'
  end

  def conjure_tag_name
    "vendor/#{name}/#{version || conjured_revision}"
  end

  def conjure_commit_message
    rv = "Conjured git module #{name} "
    rv << "version #{version} " if version
    rv << "revision #{conjured_revision}"
    rv
  end

  install!
end
