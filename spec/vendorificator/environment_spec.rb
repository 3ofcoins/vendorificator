require 'spec_helper'

module Vendorificator
  describe Environment do
    let(:environment) do
      Environment.new(
        Thor::Shell::Basic.new,
        :quiet,
        'spec/vendorificator/fixtures/vendorfiles/vendor.rb'
      )
    end

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
        environment.git.expects(:fetch).with('origin')
        environment.git.expects(:fetch).with({:tags => true}, 'origin')
        @git_fetch_notes = environment.git.expects(:fetch).with('origin', 'refs/notes/vendor:refs/notes/vendor')
        environment.git.capturing.stubs(:show_ref).returns("602315 refs/remotes/origin/vendor/test\n")
        environment.vendor_instances = []
      end

      it "creates a branch if it doesn't exist" do
        environment.vendor_instances << stub(:branch_name => 'vendor/test', :head => nil)

        environment.git.expects(:branch).with({:track => true}, 'vendor/test', '602315')

        environment.pull('origin')
      end

      it "handles fast forwardable branches" do
        environment.vendor_instances << stub(
          :branch_name => 'vendor/test', :head => '123456', :in_branch => true, :name => 'test')
        environment.expects(:fast_forwardable?).returns(true)

        environment.pull('origin')
      end

      it "handles git error on fetching empty notes" do
        @git_fetch_notes.raises(MiniGit::GitError)

        environment.pull('origin')
      end
    end

    describe '#push' do
      it "handles git error on pushing empty notes" do
        environment.stubs(:ensure_clean!)
        environment.vendor_instances = []

        environment.git.capturing.expects(:rev_parse).with({:quiet => true, :verify => true}, 'refs/notes/vendor').raises(MiniGit::GitError)
        environment.git.expects(:push).with('origin', [])
        environment.git.stubs(:push).with('origin', :tags => true)

        environment.push(:remote => 'origin')
      end

      it "pushes note when they exist" do
        environment.stubs(:ensure_clean!)
        environment.vendor_instances = []

        environment.git.capturing.expects(:rev_parse).with({:quiet => true, :verify => true}, 'refs/notes/vendor').returns('abcdef')
        environment.git.expects(:push).with('origin', ['refs/notes/vendor'])
        environment.git.stubs(:push).with('origin', :tags => true)

        environment.push(:remote => 'origin')
      end
    end

    describe '#vendor_instances' do
      let(:environment) do
        Environment.new(
          Thor::Shell::Basic.new,
          :default,
          'spec/vendorificator/fixtures/vendorfiles/empty_vendor.rb'
        )
      end

      it 'is initialized on a new environment' do
        assert { environment.vendor_instances == [] }
      end

      it 'allows to add/read instances' do
        environment.vendor_instances << :foo
        assert { environment.vendor_instances == [:foo] }
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
