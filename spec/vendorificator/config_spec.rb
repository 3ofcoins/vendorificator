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
  end
end
