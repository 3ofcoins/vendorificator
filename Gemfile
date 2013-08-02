source 'https://rubygems.org'

# Specify your gem's dependencies in vendorificator.gemspec
gemspec

group :development do
  git "git://github.com/sconover/wrong.git",
      :ref => '0cbc35a07cb63f6f409bb85da6ad7d107bdab021' do
    gem 'wrong'
  end

  git "git://github.com/cucumber/cucumber.git",
      :ref => 'd7452d0a0b7998462e28d10f9d2733947984063d' do
    gem 'cucumber'
  end
end

group :development_workstation do
  gem "pry"
  gem "awesome_print"
  gem "relish"
  gem 'debugger'
end
