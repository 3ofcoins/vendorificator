require 'spec_helper'

module Vendorificator
  describe Vendor::Git do

    describe '#metadata' do
      before do
        @vendor = Vendor::Git.new(basic_environment,
          'git://github.com/mpasternacki/nagios.git'
        )
        @vendor.stubs(:version).returns('0.23')
      end

      let(:metadata) { @vendor.metadata }

      it 'contains the repository url' do
        assert { metadata[:parsed_args][:repository] =~ /mpasternacki\/nagios\.git/ }
      end
    end

  end
end

