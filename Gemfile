source 'https://rubygems.org'

# Specify your gem's dependencies in vendorificator.gemspec
gemspec

group :development do
  git "git://github.com/mpasternacki/wrong.git",
      :ref => 'ad025241e5772373264d1bf62168e2bf3780ccf9' do
    gem 'wrong'
  end
  gem 'minitest-ansi'
end

group :development_workstation do
  gem "pry"
  gem "awesome_print"
  gem "relish"
end
