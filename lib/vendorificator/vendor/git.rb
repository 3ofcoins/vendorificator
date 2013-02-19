require 'fileutils'
require 'vendorificator/vendor'

class Vendorificator::Vendor::Git < Vendorificator::Vendor
  arg_reader :repository, :revision, :branch
  attr_reader :git, :conjured_revision

  def initialize(name, args={}, &block)
    unless args.include?(:repository)
      args[:repository] = name
      name = name.split('/').last.sub(/\.git$/, '')
    end
    super(name, args, &block)
  end

  def conjure!
    shell.say_status :clone, repository
    MiniGit.git :clone, repository, '.'
    @git = MiniGit.new('.')

    if revision
      git.checkout({:b => 'vendorified'}, revision)
    elsif branch
      git.checkout({:b => 'vendorified'}, "origin/#{branch}")
    end

    super

    @conjured_revision = git.capturing.rev_parse('HEAD').strip
    FileUtils::rm_rf '.git'
  end

  def upstream_version
    conjured_revision
  end

  def conjure_commit_message
    rv = "Conjured git module #{name} "
    rv << "version #{version} " if version
    rv << "revision #{conjured_revision}"
    rv
  end

  install!
end
