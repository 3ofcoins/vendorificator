require 'rubygems'
require 'bundler/setup'
Bundler.setup

require 'minitest/spec'
require 'minitest/autorun'
require 'vcr'
require 'mocha/setup'
require 'wrong'
require 'wrong/adapters/minitest'

begin
  require 'minitest/ansi'
rescue LoadError                # that's fine, we'll live without it
else
  MiniTest::ANSI.use! if STDOUT.tty?
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
  def conf
    @conf ||= Vendorificator::Config.new
  end

  def basic_environment
    @basic_environment ||= Vendorificator::Environment.new
  end

  def includes_method?(obj, method)
    (obj.methods.include? method.to_sym) || (obj.methods.include? method.to_s)
  end
end
