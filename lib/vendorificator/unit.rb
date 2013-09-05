module Vendorificator
  class Unit

    def in_branch(options = {}, &block)
      branch_exists = !!head
      Dir.mktmpdir "vendor-#{group}-#{name}" do |tmpdir|
        clone_opts = {:shared => true, :no_checkout => true}
        clone_opts[:branch] = branch_name if branch_exists
        say { MiniGit::Capturing.git :clone, clone_opts, git.git_dir, tmpdir }

        tmpgit = MiniGit.new(tmpdir)
        tmpgit.capturing.checkout({orphan: true}, branch_name) unless branch_exists
        tmpgit.fetch git.git_dir, "refs/notes/vendor:refs/notes/vendor" if notes_exist
        if options[:clean] || !branch_exists
          tmpgit.rm({ :r => true, :f => true, :q => true, :ignore_unmatch => true }, '.')
        end

        begin
          @git = tmpgit
          @vendor.git = tmpgit

          Dir.chdir tmpdir do
            yield
          end
        ensure
          @git = nil
          @vendor.git = nil
        end

        git.fetch tmpdir
        git.fetch({tags: true}, tmpdir)
        git.fetch tmpdir,
          "refs/heads/#{branch_name}:refs/heads/#{branch_name}",
          "refs/notes/vendor:refs/notes/vendor"
      end
    end

    def run!(options = {})
      case status

      when :up_to_date
        say_status :default, 'up to date', to_s

      when :unpulled, :unmerged
        say_status :default, 'merging', to_s, :yellow
        @vendor.merge_back tagged_sha1
        postprocess! if self.respond_to? :postprocess!
        compute_dependencies!

      when :outdated, :new
        say_status :default, 'fetching', to_s, :yellow
        begin
          shell.padding += 1
          @vendor.before_conjure!
          in_branch(:clean => true) do
            FileUtils::mkdir_p work_dir

            # Actually fill the directory with the wanted content
            Dir::chdir work_dir do
              begin
                shell.padding += 1
                @vendor.conjure!
              ensure
                shell.padding -= 1
              end

              subdir = @vendor.args[:subdirectory]
              make_subdir_root subdir if subdir && !subdir.empty?
            end

            commit_and_annotate(options[:metadata])
          end
          # Merge back to the original branch
          merge_back
          @vendor.postprocess! if @vendor.respond_to? :postprocess!
          @vendor.compute_dependencies!
        ensure
          shell.padding -= 1
        end

      else
        say_status :quiet, self.status, "I'm unsure what to do.", :red
      end
    end

    def head
      git.capturing.rev_parse({:verify => true, :quiet => true}, "refs/heads/#{branch_name}").strip
    rescue MiniGit::GitError
      nil
    end

    def compute_dependencies!
      @vendor.compute_dependencies!
    end

    def name
      @vendor.name
    end

    def pushable_refs
      created_tags.unshift("refs/heads/#{branch_name}")
    end

    def overlay
      @vendor.overlay
    end

    def work_dir
      _join(git.git_work_tree, environment.relative_root_dir, work_subdir)
    end

    def included_in_list?(module_list)
      @vendor.included_in_list? module_list
    end

    def group
      @vendor.group
    end

    def status
      @vendor.status
    end

    def updatable?
      @vendor.updatable?
    end

    def merged_version
      @vendor.merged_version
    end

    def version
      @vendor.version
    end

    def to_s
      _join name, version
    end

    def merged_notes
      @vendor.merged_notes
    end

    def tag_name_base
      @vendor.send :tag_name_base
    end

    def branch_name
      @vendor.branch_name
    end

    def config
      environment.config
    end

    private

    # Private: Commits and annotates the conjured module.
    #
    # environment_metadata - Hash with environment metadata where vendor was run
    #
    # Returns nothing.
    def commit_and_annotate(environment_metadata = {})
      git.capturing.add work_dir, *@vendor.git_add_extra_paths
      git.capturing.commit :m => @vendor.conjure_commit_message
      git.capturing.notes({:ref => 'vendor'}, 'add', {:m => @vendor.conjure_note(environment_metadata)}, 'HEAD')
      git.capturing.tag( { :a => true, :m => @vendor.tag_message }, @vendor.tag_name )
      say_status :default, :tag, @vendor.tag_name
    end

    def notes_exist
      git.capturing.rev_parse({verify: true, quiet: true}, 'refs/notes/vendor')
    rescue MiniGit::GitError
      nil
    end

    def merge_back(commit = branch_name)
      git.capturing.merge({:no_edit => true, :no_ff => true}, commit)
    end

    def _join(*parts)
      parts.compact.map(&:to_s).join('/')
    end

    def environment
      @vendor.environment
    end

    def git
      @git || environment.git
    end

    def work_subdir
      _join(config[:basedir], path)
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

    def path
      @vendor.args[:path] || if overlay
          _join overlay.path, group, name
        else
          _join group, name
        end
    end

    def created_tags
      git.capturing.show_ref.lines.map{ |line| line.split(' ')[1] }.
        select{ |ref| ref =~ /\Arefs\/tags\/#{tag_name_base}\// }
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
  end
end
