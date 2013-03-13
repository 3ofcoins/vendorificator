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
        assert { Config.new.methods.include? :custom_option }
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
        assert { config.methods.include? :basedir }
        assert { config.methods.include? :branch_prefix }
        assert { config.methods.include? :remotes }
      end
    end
  end
end
