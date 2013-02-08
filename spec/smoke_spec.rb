require 'spec_helper'

module Vendorificator
  describe VERSION do
    it 'is equal to itself' do
      assert { VERSION == Vendorificator::VERSION }
    end
  end
end
