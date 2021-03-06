require 'spec_helper'

module Vendorificator
  describe Environment do
    let(:environment) { Environment.new(Thor::Shell::Basic.new, :quiet, nil){} }

    before do
      environment.git.capturing.stubs(:remote).returns("origin\n")
    end

    describe '#clean' do
      it 'returns false for dirty repo' do
        git_error = MiniGit::GitError.new(['command'], 'status')
        environment.git.expects(:update_index).raises(git_error)

        assert { environment.clean? == false }
      end

      it 'returns true for a clean repo' do
        environment.git.expects(:update_index)
        environment.git.expects(:diff_files)
        environment.git.expects(:diff_index)

        assert { environment.clean? == true }
      end
    end

    describe '#pull_all' do
      it 'aborts on a dirty repo' do
        environment.expects(:clean?).returns(false)

        assert { rescuing { environment.pull_all }.is_a? DirtyRepoError }
      end

      it 'pulls multiple remotes if specified' do
        environment.stubs(:clean?).returns(true)
        environment.expects(:pull).with('origin_1', anything)
        environment.expects(:pull).with('origin_2', anything)

        environment.pull_all(:remote => 'origin_1,origin_2')
      end
    end

    describe '#pull' do
      before do
        @fetch = environment.git.expects(:fetch).with({:quiet => true}, 'origin',
          'refs/heads/vendor/*:refs/remotes/origin/vendor/*',
          'refs/tags/*:refs/tags/*',
          'refs/notes/vendor:refs/notes/vendor')
        environment.git.capturing.stubs(:show_ref).returns("602315 refs/remotes/origin/vendor/test\n")
      end

      it "creates a branch if it doesn't exist" do
        environment.segments << stub(
          :name => 'test',
          :branch_name => 'vendor/test',
          :head => nil,
          :compute_dependencies! => nil)

        environment.git.expects(:branch).with({:track => true, :quiet => true}, 'vendor/test', 'origin/vendor/test')

        environment.pull('origin')
      end

      it "handles fast forwardable branches" do
        environment.segments << stub(
          :branch_name => 'vendor/test', :head => '123456', :fast_forward => true,
          :name => 'test', :compute_dependencies! => nil
        )
        environment.expects(:fast_forwardable?).returns(true)

        environment.pull('origin')
      end

      it "handles git error on fetching empty notes" do
        @fetch.raises(MiniGit::GitError)
        environment.pull('origin')
      end
    end

    describe '#push' do
      it "handles git error on pushing empty notes" do
        environment.stubs(:ensure_clean!)

        environment.git.capturing.expects(:rev_parse).with({:quiet => true, :verify => true}, 'refs/notes/vendor').raises(MiniGit::GitError)
        environment.git.expects(:push).with('origin', [])
        environment.git.stubs(:push).with('origin', :tags => true)

        environment.push(:remote => 'origin')
      end

      it "pushes note when they exist" do
        environment.stubs(:ensure_clean!)

        environment.git.capturing.expects(:rev_parse).with({:quiet => true, :verify => true}, 'refs/notes/vendor').returns('abcdef')
        environment.git.expects(:push).with('origin', ['refs/notes/vendor'])
        environment.git.stubs(:push).with('origin', :tags => true)

        environment.push(:remote => 'origin')
      end
    end

    describe '#segments' do
      it 'is initialized on a new environment' do
        assert { environment.segments == [] }
      end

      it 'allows to add/read instances' do
        environment.segments << :foo
        assert { environment.segments == [:foo] }
      end
    end

    describe '#metadata_snapshot' do
      before do
        environment.git.capturing.stubs(:rev_parse).with({:abbrev_ref => true}, 'HEAD').returns("current_branch\n")
        environment.git.capturing.stubs(:rev_parse).with('HEAD').returns("123456\n")
        environment.git.capturing.stubs(:describe).returns("git description\n")
        @metadata = environment.metadata_snapshot
      end

      it 'contains vendorificator version information' do
        assert { @metadata.keys.include? :vendorificator_version }
      end

      it 'contains current branch information' do
        assert { @metadata[:current_branch] == 'current_branch' }
        assert { @metadata[:current_sha] == '123456' }
      end

      it 'contains git describe information' do
        assert { @metadata[:git_describe] == 'git description' }
      end
    end

  end
end
