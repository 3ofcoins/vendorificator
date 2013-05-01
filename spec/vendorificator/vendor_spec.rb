# Note that due to git operations involved, most of the Vendor class is tested
# with cucumber features instead.
require 'spec_helper'

module Vendorificator
  class Vendor::Categorized < Vendor
    @category = :test
  end

  class Vendor::Custom < Vendor
    @method_name = :whatever
  end

  describe Vendor do
    describe '.category' do
      it 'defaults to nil' do
        assert { Vendor.category == nil }
      end

      it 'can be overridden in a subclass' do
        assert { Vendor::Categorized.category == :test }
      end
    end

    describe '#category' do
      it 'defaults to class attribute' do
        assert { Vendor.new(basic_environment, 'test').category == nil }
        assert { Vendor::Categorized.new(basic_environment, 'test').category == :test }
      end

      it 'can be overriden by option' do
        assert { Vendor.new(basic_environment, 'test', :category => :foo).category == :foo }
        assert { Vendor::Categorized.new(basic_environment, 'test', :category => :foo).category == :foo }
      end

      it 'can be reset to nil by option' do
        assert { Vendor::Categorized.new(basic_environment, 'test', :category => nil).category == nil }
      end

      it 'is inserted into paths and other names' do
        uncategorized = Vendor.new(basic_environment, 'test')
        categorized   = Vendor.new(basic_environment, 'test', :category => :cat)

        deny { uncategorized.branch_name.include? 'cat' }
        assert { categorized.branch_name.include? 'cat' }

        deny { uncategorized.path.include? 'cat' }
        assert { categorized.path.include? 'cat' }

        uncategorized.stubs(:version).returns(:foo)
        categorized.stubs(:version).returns(:foo)
        deny { uncategorized.tag_name.include? 'cat' }
        assert { categorized.tag_name.include? 'cat' }
      end
    end

    describe '#initialize' do
      it 'adds hooks' do
        vendor = Vendor.new(basic_environment, 'test', {:hooks => 'FooHook'})
        assert { includes_method? vendor, :foo_hooked_method }
      end
    end
  end
end

module Vendorificator
  module Hooks
    module FooHook
      def foo_hooked_method; end
    end
  end
end
