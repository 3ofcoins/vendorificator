require 'rubygems'
require 'bundler/setup'
Bundler.setup

require 'minitest/autorun'
require 'vcr'
require 'mocha/setup'
require 'wrong'

module Vendorificator
  module Spec
    module Helpers
      module Wrong
        include ::Wrong::Assert
        include ::Wrong::Helpers

        def increment_assertion_count
          self.assertions += 1
        end
      end
    end
  end
end

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_group 'Vendors', 'lib/vendorificator/vendor'
    use_merging
  end
  SimpleCov.command_name 'rake spec'
end

require 'vendorificator'

VCR.configure do |config|
  config.cassette_library_dir = 'features/fixtures/vcr'
  config.default_cassette_options = { :record => :new_episodes }
  config.hook_into :webmock
end

class MiniTest::Spec
  include Vendorificator::Spec::Helpers::Wrong

  before do
    _git = stub('git')
    _capturing = stub('git.capturing')
    _git.stubs(:capturing).returns(_capturing)
    Vendorificator::Environment.any_instance.stubs(:git).returns(_git)
  end

  def conf
    @conf ||= Vendorificator::Config.new
  end

  def basic_environment
    @basic_environment ||= Vendorificator::Environment.new(
      Thor::Shell::Basic.new, :quiet, nil
    )
  end

  def includes_method?(obj, method)
    (obj.methods.include? method.to_sym) || (obj.methods.include? method.to_s)
  end
end
