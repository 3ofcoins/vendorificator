require_relative '../../spec_helper'

module Vendorificator
  describe Segment::Vendor do
    describe '#initialize' do
      let(:segment){ Segment::Vendor.new(overlay: 'test', vendor: 'vendor') }

      it 'assigns overlay' do
        assert { segment.overlay == 'test' }
      end

      it 'assigns vendor' do
        assert { segment.vendor == 'vendor' }
      end
    end
  end
end


