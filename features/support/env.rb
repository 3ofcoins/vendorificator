require 'fileutils'
require 'pathname'
require 'tmpdir'

require 'aruba/cucumber'
require 'wrong'

require 'vendorificator/cli'

MiniGit.debug = true if ENV['CUCUMBER_DEBUG']

ENV['GIT_AUTHOR_NAME'] = ENV['GIT_COMMITTER_NAME'] = 'Vendorificator Cucumber'
ENV['GIT_AUTHOR_EMAIL'] = ENV['GIT_COMMITTER_EMAIL'] = 'nonexistent@example.com'

World(Wrong)

ENV['FIXTURES_DIR'] = Pathname.new(__FILE__).
  dirname.join('..', 'fixtures').realpath.to_s

# https://github.com/cucumber/aruba/pull/144
After do
  processes.clear
end

Before do
  @aruba_timeout_seconds = case defined?(RUBY_ENGINE) && RUBY_ENGINE
                           when 'jruby' then 45
                           when 'rbx' then 30
                           else 30
                           end
end
