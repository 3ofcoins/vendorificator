module Vendorificator
  class Segment

    def initialize(args = {})
      @metadata = {}
    end

    def fast_forward(branch)
      in_branch do |tmpgit|
        tmpgit.checkout(:quiet => true)
        tmpgit.merge({:ff_only => true, :quiet => true}, branch)
      end
    end

    def status
      # If there's no branch yet, it's a completely new module
      return :new unless head

      # If there's a branch but no tag, it's a known module that's not
      # been updated for the new definition yet.
      return :outdated unless tagged_sha1

      # Well, this is awkward: branch is in config and exists, but is
      # not merged into current branch at all.
      return :unmerged unless merged?

      # Merge base is tagged with our tag. We're good.
      return :up_to_date if tagged_sha1 == merged_base

      return :unpulled if environment.fast_forwardable?(tagged_sha1, merged_base)

      return :unknown
    end

    def run!(options = {})
      say_status :default, :module, name
      indent do
        case status

        when :up_to_date
          say_status :default, 'up to date', to_s

        when :unpulled, :unmerged
          say_status :default, 'merging', to_s, :yellow
          merge_back tagged_sha1

        when :outdated, :new
          say_status :default, 'fetching', to_s, :yellow
          update options

        else
          say_status :quiet, self.status, "I'm unsure what to do.", :red
        end
      end
    end

    def pushable_refs
      created_tags.unshift("refs/heads/#{branch_name}")
    end

    def work_dir(relative = false)
      arr = relative ? [] : [git.git_work_tree]
      arr << environment.relative_root_dir
      arr << work_subdir

      _join *arr
    end

    def included_in_list?(module_list)
      modpaths = module_list.map { |m| File.expand_path(m) }

      module_list.include?(name) ||
        module_list.include?("#{group}/#{name}") ||
        modpaths.include?(File.expand_path(work_dir)) ||
        module_list.include?(merged_base) ||
        module_list.include?(branch_name)
    end

    def updatable?
      return nil if self.status == :up_to_date
      return false if !head
      return false if head && merged_base == head
      git.describe({:abbrev => 0, :always => true}, branch_name)
    end

    def to_s
      _join name, version
    end

    # Public: Get git vendor notes of the merged commit.
    #
    # Returns the Hash of git vendor notes.
    def merged_notes
      Commit.new(merged_base, git).notes?
    end

    def merged_version
      merged_tag && merged_tag[(1 + tag_name_base.length)..-1]
    end


    def head
      git.capturing.rev_parse({:verify => true, :quiet => true}, "refs/heads/#{branch_name}").strip
    rescue MiniGit::GitError
      nil
    end

    private

    def config
      environment.config
    end

    # Private: Commits and annotates the conjured module.
    #
    # environment_metadata - Hash with environment metadata where vendor was run
    #
    # Returns nothing.
    def commit_and_annotate(environment_metadata = {})
      return if config.fake_mode?

      git.capturing.add work_dir, *@vendor.git_add_extra_paths
      git.capturing.commit :m => @vendor.conjure_commit_message
      git.capturing.notes({:ref => 'vendor'}, 'add', {:m => conjure_note(environment_metadata)}, 'HEAD')
      git.capturing.tag( { :a => true, :m => tag_message }, tag_name )
      say_status :default, :tag, tag_name
    end

    # Private: Merges all the data we use for the commit note.
    #
    # environment_metadata - Hash with environment metadata where vendor was run
    #
    # Returns: The note in the YAML format.
    def conjure_note(environment_metadata = {})
      config.metadata.
        merge(environment_metadata).
        merge(metadata).
        merge(@vendor.metadata).
        to_yaml
    end

    def in_branch(branch = branch_name, options = {}, &block)
      Dir.mktmpdir do |tmpdir|
        tmpgit = create_temp_git_repo(branch, options, tmpdir)
        fetch_repo_data tmpgit

        Dir.chdir(tmpdir){ yield tmpgit }

        propagate_repo_data_to_original branch, tmpdir
      end
    end

    def create_temp_git_repo(branch, options, dir)
      clone_opts = {shared: true, no_checkout: true, quiet: true}
      clone_opts[:branch] = branch if branch_exists? branch
      MiniGit.git(:clone, clone_opts, git.git_dir, dir)

      tmpgit = MiniGit.new(dir)
      unless branch_exists? branch
        tmpgit.capturing.checkout({quiet: true}, {orphan: true}, branch)
        tmpgit.capturing.rm({ :r => true, :f => true, :q => true, :ignore_unmatch => true }, '.')
      end

      tmpgit
    end

    def fetch_repo_data(tmpgit)
      tmpgit.fetch({quiet: true}, git.git_dir, "refs/notes/vendor:refs/notes/vendor") if notes_exist?
    end

    def propagate_repo_data_to_original(branch, clone_dir)
      if config.fake_mode?
        add_path_to_git_exclude
        copy_back_from_temporary_clone(clone_dir)
      else
        fetch_back_from_temporary_clone(branch, clone_dir)
      end
    end

    # Private: Fetches the branches from the temporary clone in the main repo,
    # to get the conjured data.
    #
    # branch - branch name to fetch
    # clone_dir - path to the local temporary clone
    #
    # Returns nothing.
    def fetch_back_from_temporary_clone(branch, clone_dir)
      git.fetch({quiet: true}, clone_dir,
        "refs/heads/#{branch}:refs/heads/#{branch}",
        "refs/tags/*:refs/tags/*",
        "refs/notes/vendor:refs/notes/vendor")
    end

    # Private: Copies the conjured vendor files back to main repo, instead of
    # just fetching the branches. Used in fake development mode.
    #
    # clone_dir - path to the local temporary clone
    #
    # Returns nothing.
    def copy_back_from_temporary_clone(clone_dir)
      FileUtils.mkdir_p work_dir
      FileUtils.cp_r clone_dir, work_dir
    end

    # Private: adds conjured directory path to git exclude file. Used in fake
    # mode.
    #
    # Returns nothing.
    def add_path_to_git_exclude
      return if check_if_work_dir_excluded

      if File.exists? work_dir
        say_status(:quiet, 'FATAL', "Directory #{work_dir(true).inspect} already exists. Aborting.", :red)
        exit
      end
      File.open('.git/info/exclude', 'a') { |f| f.puts work_dir(true) }
    end

    # Private: Checks if segment work_dir has already been excluded.
    #
    # Returns true/false.
    def check_if_work_dir_excluded
      File.open('.git/info/exclude').each_line.any? do |line|
        line =="#{work_dir(true)}\n"
      end
    end

    def in_work_dir
      FileUtils::mkdir_p work_dir

      Dir::chdir work_dir do
        begin
          shell.padding += 1
          yield
        ensure
          shell.padding -= 1
        end
      end
    end

    def notes_exist?
      git.capturing.rev_parse({verify: true, quiet: true}, 'refs/notes/vendor')
      true
    rescue MiniGit::GitError
      false
    end

    def metadata
      default = {
      }
      default.merge @metadata
    end

    def name
      raise NotImplementedError
    end

    def version
      raise NotImplementedError
    end

    def tag_message
      @vendor.conjure_commit_message
    end

    def _join(*parts)
      parts.compact.map(&:to_s).join('/')
    end

    def git
      @git || environment.git
    end

    def make_subdir_root(subdir_path)
      curdir = Pathname.pwd
      tmpdir = Pathname.pwd.dirname.join("#{Pathname.pwd.basename}.tmp")
      subdir = Pathname.pwd.join(subdir_path)

      Dir.chdir('..')

      subdir.rename(tmpdir.to_s)
      curdir.rmtree
      tmpdir.rename(curdir.to_s)
    ensure
      Dir.chdir(curdir.to_s) if curdir.exist?
    end

    def created_tags
      git.capturing.show_ref.lines.map{ |line| line.split(' ')[1] }.
        select{ |ref| ref =~ /\Arefs\/tags\/#{tag_name_base}\// }
    end

    def tagged_sha1
      @tagged_sha1 ||= git.capturing.rev_parse(
        {:verify => true, :quiet => true}, "refs/tags/#{tag_name}^{commit}"
      ).strip
    rescue MiniGit::GitError
      nil
    end

    def group
      nil
    end

    def branch_name
      _join(config[:branch_prefix], group, name)
    end

    def tag_name
      _join(tag_name_base, version)
    end

    def tag_name_base
      branch_name
    end

    def merged_base
      return nil if !head
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

    # Private: Checks whether a particular branch exists.
    #
    # branch - name of the branch to check, default to segment branch
    #
    # Returns true/false.
    def branch_exists?(branch = branch_name)
      git.capturing.rev_parse({:verify => true, :quiet => true}, "refs/heads/#{branch}")
      true
    rescue MiniGit::GitError
      false
    end

    def shell
      environment.shell
    end

    def say(verb_level= :default, &block)
      output = yield
      environment.say verb_level, output
    end

    def say_status(*args, &block)
      environment.say_status(*args, &block)
    end

    def indent(verb_level = :default, *args, &block)
      say_status verb_level, *args unless args.empty?
      shell.padding += 1 if shell
      yield
    ensure
      shell.padding -= 1 if shell
    end
  end
end
