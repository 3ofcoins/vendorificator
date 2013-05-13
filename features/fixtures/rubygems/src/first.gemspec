Gem::Specification.new do |gem|
  gem.name          = "first"
  gem.version       = '0'
  gem.authors       = ["Test"]
  gem.email         = ["maciej@example.com"]
  gem.summary       = "First test gem"
  gem.description   = "First test gem, the"
  gem.homepage      = "http://example.com/"

  gem.files         = [ 'README.md' ]
  gem.executables   = []
  gem.test_files    = []
  gem.require_paths = [ 'lib' ]

  gem.add_dependency "second"
end
