# Note that due to git operations involved, most of the Vendor class is tested
# with cucumber features instead.
require_relative '../spec_helper'

module Vendorificator
  class Vendor::Categorized < Vendor
    @group = :test
  end

  class Vendor::Custom < Vendor
    @method_name = :whatever
  end

  describe Vendor do
    describe '.group' do
      it 'defaults to nil' do
        assert { Vendor.group == nil }
      end

      it 'can be overridden in a subclass' do
        assert { Vendor::Categorized.group == :test }
      end
    end

    describe '#group' do
      it 'defaults to class attribute' do
        assert { Vendor.new(basic_environment, 'test').group == nil }
        assert { Vendor::Categorized.new(basic_environment, 'test').group == :test }
      end

      it 'can be overriden by option' do
        assert { Vendor.new(basic_environment, 'test', :group => :foo).group == :foo }
        assert { Vendor::Categorized.new(basic_environment, 'test', :group => :foo).group == :foo }
      end

      it 'can be reset to nil by option' do
        assert { Vendor::Categorized.new(basic_environment, 'test', :group => nil).group == nil }
      end

      it 'is inserted into paths and other names' do
        uncategorized = Vendor.new(basic_environment, 'test')
        categorized   = Vendor.new(basic_environment, 'test', :group => :cat)

        deny { uncategorized.branch_name.include? 'cat' }
        assert { categorized.branch_name.include? 'cat' }

        deny { uncategorized.unit.send(:path).include? 'cat' }
        assert { categorized.unit.send(:path).include? 'cat' }

        uncategorized.stubs(:version).returns(:foo)
        categorized.stubs(:version).returns(:foo)
        deny { uncategorized.tag_name.include? 'cat' }
        assert { categorized.tag_name.include? 'cat' }
      end

      it 'accepts a deprecated :category option' do
        vendor = Vendor.new(basic_environment, 'test', :category => 'foo')

        assert { vendor.group == 'foo' }
      end
    end

    describe '#metadata' do
      before do
        @vendor = Vendor.new(basic_environment, 'name_test',
          :group => 'cat_test', :test_arg => 'test_value'
        )
        @vendor.stubs(:version).returns('0.23')
      end

      it 'contains the module version' do
        assert { @vendor.metadata[:module_version] == '0.23' }
      end

      it 'contains the group' do
        assert { @vendor.metadata[:module_group] == 'cat_test' }
      end

      it 'contains the name' do
        assert { @vendor.metadata[:module_name] == 'name_test' }
      end

      it 'contains the parsed arguments' do
        assert { @vendor.metadata[:parsed_args].keys.include? :test_arg }
      end

      it 'contains the unparsed arguments' do
        assert { @vendor.metadata[:unparsed_args].keys.include? :group }
      end
    end

    describe '#initialize' do
      it 'adds hooks when you pass a module option' do
        vendor = Vendor.new(basic_environment, 'test', {:hooks => Hooks::FooHook})
        assert { includes_method? vendor, :foo_hooked_method }
      end

      it 'adds hooks via the String option shortcut' do
        vendor = Vendor.new(basic_environment, 'test', {:hooks => 'FooHook'})
        assert { includes_method? vendor, :foo_hooked_method }
      end

      it 'assigns to an overlay' do
        overlay = Overlay.new('/')
        vendor = Vendor.new(basic_environment, 'test', {overlay: overlay})
        assert { vendor.overlay == overlay }
      end
    end

    describe '#included_in_list?' do
      let(:vendor) { Vendor.new(basic_environment, 'test_name', :group => 'test_group') }

      it 'finds a module by name' do
        assert { vendor.included_in_list?(['test_name']) }
      end

      it 'finds a module by qualified name' do
        assert { vendor.included_in_list?(['test_group/test_name']) }
      end

      it 'finds a module by path' do
        vendor.stubs(:work_dir).returns('./vendor/test_group/test_name')

        assert { vendor.included_in_list?(['./vendor/test_group/test_name']) }
      end

      it 'finds a module by merge commit' do
        vendor.stubs(:merged_base).returns('foobar')
        vendor.stubs(:work_dir).returns('abc/def')

        assert { vendor.included_in_list?(['foobar']) }
      end

      it 'finds a module by branch name' do
        vendor.stubs(:merged_base).returns('abcdef')
        vendor.stubs(:work_dir).returns('abc/def')

        vendor.stubs(:branch_name).returns('foo/bar')
        assert { vendor.included_in_list?(['foo/bar']) }
      end

    end
  end

  module Hooks
    module FooHook
      def foo_hooked_method; end
    end
  end
end
