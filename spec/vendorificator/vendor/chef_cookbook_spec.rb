require File.expand_path("../../../spec_helper", __FILE__)

module Vendorificator
  describe Vendor::ChefCookbook do
    describe 'config extensions' do
      describe 'options' do
        it 'registers chef_cookbook_ignore_dependencies' do
          assert { includes_method? Config.new, :chef_cookbook_ignore_dependencies }
        end
      end
    end
  end
end
