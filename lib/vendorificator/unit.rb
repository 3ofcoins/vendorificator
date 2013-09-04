module Vendorificator
  class Unit

    def in_branch(options={}, &block)
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
          @vendor.instance_variable_set :@git, tmpgit
          Dir.chdir tmpdir do
            yield
          end
        ensure
          @vendor.instance_variable_set :@git, nil
        end

        git.fetch tmpdir
        git.fetch({tags: true}, tmpdir)
        git.fetch tmpdir,
          "refs/heads/#{branch_name}:refs/heads/#{branch_name}",
          "refs/notes/vendor:refs/notes/vendor"
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

    def run!(options = {})
      @vendor.run! options
    end

    def work_dir
      @vendor.work_dir
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

    private

    def notes_exist
      git.capturing.rev_parse({verify: true, quiet: true}, 'refs/notes/vendor')
    rescue MiniGit::GitError
      nil
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
