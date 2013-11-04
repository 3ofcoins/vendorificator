require File.expand_path("../../spec_helper", __FILE__)

module Vendorificator
  describe Config do
    let(:config){ Config.new }

    describe '#initialize' do
      it' creates a Config object' do
        assert { config.is_a? Config }
      end

      it 'allows to overwrite the default configuration' do
        config = Config.new(:basedir => 'different/basedir')
        assert { config[:basedir] == 'different/basedir' }
      end
    end

    it 'allows to set and get values' do
      assert { config[:new_value] == nil }
      config[:new_value] = 'new value'

      assert { config[:new_value] == 'new value' }
    end

    describe 'extensions' do
      before do
        class Config
          option :custom_option, :default_value
        end
      end

      it 'allows to define custom options' do
        assert { includes_method? Config.new, :custom_option }
      end

      it 'allows to get custom_option value via method' do
        assert { Config.new.custom_option == :default_value }
      end

      it 'allows to set custom_option via method' do
        config.custom_option :custom_value
        assert { config[:custom_option] == :custom_value }
      end

      it 'sets a default value for custom option' do
        assert { Config.new[:custom_option] == :default_value }
      end
    end

    describe 'options' do
      it 'have default values' do
        assert { config[:basedir] == 'vendor' }
        assert { config[:branch_prefix] == 'vendor' }
        assert { config[:remotes] == %w(origin) }
      end

      it 'can be set' do
        assert { includes_method? config, :basedir }
        assert { includes_method? config, :branch_prefix }
        assert { includes_method? config, :remotes }
      end
    end

    describe 'metadata' do
      it 'can be set by user' do
        config.annotate :foo, :bar
        assert { config.metadata[:foo] == :bar }
      end
    end

    describe '#overlay' do
      let(:environment) do
        env = Environment.new(Thor::Shell::Basic.new, :quiet,
          'spec/vendorificator/fixtures/vendorfiles/overlay.rb'
        )
        env.load_vendorfile

        env
      end

      it 'assigns an overlay instance to all segments in the block' do
        overlay = environment.segments.first
        assert { overlay.segments.size > 1 }
        overlay.each_segment do |seg|
          assert { seg.overlay != nil }
        end
      end

      it 'assigns the same overlay instance to all segments in the block' do
        overlay = environment.segments.first
        assert { overlay.segments.size > 1 }
        overlay.each_segment do |vendor|
          assert { vendor.overlay == overlay }
        end
      end
    end

    describe 'fake_mode?' do
      it 'returns false when config not set' do
        MiniGit::Capturing.stubs(:git).with(:config, 'vendorificator.stub').raises(MiniGit::GitError)
        assert { config.fake_mode? == false }
      end

      it 'returns true when set to any truish value' do
        stub_fake_mode 'any_truish_value'
        assert { config.fake_mode? == true }
      end

      it 'returns false when set to empty string' do
        stub_fake_mode ''
        assert { config.fake_mode? == false }
      end

      it 'returns false when set to false' do
        stub_fake_mode 'false'
        assert { config.fake_mode? == false }
      end

      it 'returns false when set to no' do
        stub_fake_mode 'no'
        assert { config.fake_mode? == false }
      end

      it 'returns false when set to 0' do
        stub_fake_mode '0'
        assert { config.fake_mode? == false }
      end
    end

    private

    def stub_fake_mode(value)
      MiniGit::Capturing.stubs(:git).with(:config, 'vendorificator.stub').
        returns(value)
    end
  end
end
