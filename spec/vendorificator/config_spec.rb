require File.expand_path("../../spec_helper", __FILE__)

module Vendorificator
  describe Config do
    let(:config){ Config.new }

    describe '#initialize' do
      it' creates a Config object' do
        config.is_a? Config
      end

      it 'saves the default params' do
        config[:basedir].must_equal 'vendor'
        config[:branch_prefix].must_equal 'vendor'
        config[:remotes].must_equal %w(origin)
      end

      it 'allows to overwrite the default configuration' do
        config = Config.new(:basedir => 'different/basedir')
        config[:basedir].must_equal 'different/basedir'
      end
    end

    it 'allows to set and get values' do
      config[:new_value].must_equal nil
      config[:new_value] = 'new value'

      config[:new_value].must_equal 'new value'
    end
  end

  describe 'extensions' do
    before do
      class Config
        option :custom_option, :default_value
      end
    end

    it 'allows to define custom options' do
      Config.new.methods.must_include :custom_option
    end

    it 'sets a default value for custom option' do
      Config.new[:custom_option].must_equal :default_value
    end
  end
end
