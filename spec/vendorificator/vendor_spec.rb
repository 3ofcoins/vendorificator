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

    describe '#metadata' do
      before do
        @vendor = Vendor.new(basic_environment, 'name_test',
          :category => 'cat_test', :test_arg => 'test_value'
        )
        @vendor.stubs(:version).returns('0.23')
      end

      it 'contains the module version' do
        assert { @vendor.metadata[:module_version] == '0.23' }
      end

      it 'contains the category' do
        assert { @vendor.metadata[:module_category] == 'cat_test' }
      end

      it 'contains the name' do
        assert { @vendor.metadata[:module_name] == 'name_test' }
      end

      it 'contains the parsed arguments' do
        assert { @vendor.metadata[:module_args].keys.include? :test_arg }
      end

      it 'contains the unparsed arguments' do
        assert { @vendor.metadata[:unparsed_args].keys.include? :category }
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
    end

    describe '#pushable_refs' do
      before do
        environment.git.capturing.stubs(:show_ref).returns <<EOF
a2745fdf2d7e51f139f9417c5ca045b389fa939f refs/heads/master
127eb134185e2bf34c79321819b81f8464392d45 refs/heads/vendor/cookbooks/nginx
0448bfa569d3d94dcb3e485c8da60fdb33d365f6 refs/heads/vendor/cookbooks/nginx_simplecgi
a2745fdf2d7e51f139f9417c5ca045b389fa939f refs/remotes/origin/master
127eb134185e2bf34c79321819b81f8464392d45 refs/remotes/origin/vendor/cookbooks/nginx
0448bfa569d3d94dcb3e485c8da60fdb33d365f6 refs/remotes/origin/vendor/cookbooks/nginx_simplecgi
e4646a83e6d24322958e1d7a2ed922dae034accd refs/tags/vendor/cookbooks/nginx/1.2.0
fa0293b914420f59f8eb4c347fb628dcb953aad3 refs/tags/vendor/cookbooks/nginx/1.3.0
680dee5e56a0d49ba2ae299bb82189b6f2660c9b refs/tags/vendor/cookbooks/nginx_simplecgi/0.1.0
EOF
      end

      let(:environment) do
        Environment.new do
          vendor :nginx, :category => :cookbooks
          vendor :nginx_simplecgi, :category => :cookbooks
        end
      end

      it 'includes all own refs' do
        refs = environment['nginx'].pushable_refs
        assert { refs.include? '+refs/heads/vendor/cookbooks/nginx' }
        assert { refs.include? '+refs/tags/vendor/cookbooks/nginx/1.2.0' }
        assert { refs.include? '+refs/tags/vendor/cookbooks/nginx/1.3.0' }

        refs = environment['nginx_simplecgi'].pushable_refs
        assert { refs.include? '+refs/heads/vendor/cookbooks/nginx_simplecgi' }
        assert { refs.include? '+refs/tags/vendor/cookbooks/nginx_simplecgi/0.1.0' }
      end

      it "doesn't include other modules' refs" do
        refs = environment['nginx'].pushable_refs
        deny { refs.include? '+refs/tags/vendor/cookbooks/nginx_simplecgi/0.1.0' }
      end
    end
  end

  module Hooks
    module FooHook
      def foo_hooked_method; end
    end
  end
end
