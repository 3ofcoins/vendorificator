require 'fileutils'
require 'pathname'
require 'tmpdir'

require 'wrong'

World(Wrong)

# Run each test in a temporary directory, initialized as a git repository
FileUtils::mkdir_p 'tmp'

Before do
  @orig_wd = Dir.getwd
  @tmp_wd = Dir.mktmpdir(nil, 'tmp')
  Dir.chdir(@tmp_wd)

  commit_file('README', 'Lorem ipsum dolor sit amet')
end

After do |scenario|
  Dir::chdir(@orig_wd)
  if ENV['DEBUG'] || scenario.failed?
    puts "Keeping working directory #{@tmp_wd} for debugging"
  else
    FileUtils::rm_rf(@tmp_wd)
  end
  @tmp_wd = nil
end

ENV['FIXTURES_DIR'] = Pathname.new(__FILE__).
  dirname.join('..', 'fixtures').realpath.to_s

