# -*- encoding: utf-8 -*-
require File.expand_path('../lib/vendorificator/version', __FILE__)

is_jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
is_1_9_plus = defined?(RUBY_VERSION) && RUBY_VERSION.to_f >= 1.9

Gem::Specification.new do |gem|
  gem.authors       = ["Maciej Pasternacki"]
  gem.email         = ["maciej@pasternacki.net"]
  gem.description   = "Vendor everything. Stay sane."
  gem.summary       = "Integrate third-party vendor modules into your git repository"
  gem.homepage      = "https://github.com/3ofcoins/vendorificator/"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "vendorificator"
  gem.require_paths = ["lib"]
  gem.version       = if ENV['PRERELEASE']
                        require 'minigit'
                        git_desc = MiniGit::Capturing.new(__FILE__).describe.strip.gsub('-', '.')
                        Gem::Version.new(Vendorificator::VERSION).bump.to_s << ".git.#{git_desc}"
                      else
                        Vendorificator::VERSION
                      end

  gem.add_dependency 'escape'
  gem.add_dependency 'thor', '>= 0.18.1'
  gem.add_dependency 'minigit', '>= 0.0.3'
  gem.add_dependency 'awesome_print'

  gem.add_development_dependency 'aruba', '~> 0.5.3'
  gem.add_development_dependency 'cucumber', '~> 1.3.10'
  gem.add_development_dependency 'mocha', '>= 0.14.0'
  gem.add_development_dependency 'berkshelf' unless is_jruby || !is_1_9_plus
  gem.add_development_dependency 'vcr'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'wrong', '~> 0.7'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'tee', '~> 1.0'
  gem.add_development_dependency 'minitest', '~> 5.2'
end
