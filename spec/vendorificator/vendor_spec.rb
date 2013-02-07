require 'spec_helper'

module Vendorificator
  class Vendor::Categorized < Vendor
    @category = :test
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
        assert { Vendor.new('test').category == nil }
        assert { Vendor::Categorized.new('test').category == :test }
      end

      it 'can be overriden by option' do
        assert { Vendor.new('test', :category => :foo).category == :foo }
        assert { Vendor::Categorized.new('test', :category => :foo).category == :foo }
      end

      it 'can be reset to nil by option' do
        assert { Vendor::Categorized.new('test', :category => nil).category == nil }
      end
    end
  end
end
