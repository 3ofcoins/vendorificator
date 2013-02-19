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

require 'vendorificator'

VCR.configure do |config|
  config.cassette_library_dir = 'features/fixtures/vcr'
  config.default_cassette_options = { :record => :new_episodes }
  config.hook_into :webmock
end

Vendorificator::Config[:root_dir] = Pathname.new(__FILE__).dirname

class MiniTest::Spec
  def conf
    Vendorificator::Config
  end

  before :each do
    @saved_configuration = Marshal.load(Marshal.dump(conf.configuration))
    @saved_methods = conf.methods
  end

  after :each do
    # Remove all new methods defined on Configuration over the run
    conf[:methods_to_remove!] = conf.methods - @saved_methods

    class << conf
      Vendorificator::Config[:methods_to_remove!].each do |method_to_remove|
        remove_method method_to_remove
      end
    end
    assert { conf.methods.sort == @saved_methods.sort }

    # Restore saved configuration
    conf.configuration = @saved_configuration
  end

  def vendorfile(&block)
    Vendorificator::Config.instance_eval &block
  end
end
