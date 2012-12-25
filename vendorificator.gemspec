# -*- encoding: utf-8 -*-
require File.expand_path('../lib/vendorificator/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Maciej Pasternacki"]
  gem.email         = ["maciej@pasternacki.net"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = %w(vendorify) # gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "vendorificator"
  gem.require_paths = ["lib"]
  gem.version       = Vendorificator::VERSION

  gem.add_dependency 'escape'
  gem.add_dependency 'grit'
  gem.add_dependency 'thor'

  gem.add_development_dependency 'cucumber'
  gem.add_development_dependency 'rspec-expectations'
  gem.add_development_dependency 'git'
  gem.add_development_dependency 'mixlib-config'
  gem.add_development_dependency 'mixlib-shellout'
end
