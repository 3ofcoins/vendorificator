require 'fileutils'
require 'tmpdir'

require 'git'
require 'mixlib/shellout'
require 'rspec/expectations'

# Run each test in a temporary directory, initialized as a git repository
FileUtils::mkdir_p 'tmp'

Before do
  @orig_wd = Dir.getwd
  @tmp_wd = Dir.mktmpdir(nil, 'tmp')
  Dir.chdir(@tmp_wd)

  @git = Git.init
  File.open('README', 'w') { |f| f.puts("Lorem ipsum dolor sit amet") }
  @git.add('README')
  @git.commit('Added the README file')
end

After do
  Dir::chdir(@orig_wd)
  if ENV['DEBUG']
    puts "Keeping working directory #{@tmp_wd} for debugging"
  else
    FileUtils::rm_rf(@tmp_wd)
  end
  @tmp_wd = nil
end
