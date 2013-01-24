require 'fileutils'

require 'grit'

require 'vendorificator/vendor'

class Vendorificator::Vendor::Git < Vendorificator::Vendor
  arg_reader :repository, :revision, :branch
  attr_reader :module_repo, :conjured_revision

  def initialize(name, args={}, &block)
    unless args.include?(:repository)
      args[:repository] = name
      name = name.split('/').last.sub(/\.git$/, '')
    end
    super(name, args, &block)
  end

  def conjure!
    shell.say_status :clone, repository
    Grit::Git.new('.').clone({}, repository, '.')
    @module_repo = Grit::Repo.new('.')

    if revision
      module_repo.git.checkout({:b => 'vendorified'}, revision)
    elsif branch
      module_repo.git.checkout({:b => 'vendorified'}, "origin/#{branch}")
    end

    super
    @conjured_revision = module_repo.head.commit.id
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
