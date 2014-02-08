Given /^nothing in particular$/ do
  nil # NOP
end

When /^nothing happens$/ do
  nil # NOP
end

# Configure Git username & email to unclutter console output
def configure_git
  run_simple 'git config user.name Cucumber'
  run_simple 'git config user.email cucumber@`hostname --fqdn`'
end

Given /^a repository with following Vendorfile:$/ do |vendorfile_contents|
  create_dir 'working-repository'
  cd 'working-repository'
  run_simple 'git init'
  configure_git
  write_file('README', 'Lorem ipsum dolor sit amet')
  write_file('Vendorfile', vendorfile_contents)
  run_simple 'git add .'
  run_simple 'git commit -m "New repo"'
end

Given /^a remote repository$/ do
  create_dir '../remote-repository'
  cd '../remote-repository'
  run_simple 'git init --bare'
  configure_git
  run_simple 'git config user.name Cucumber'
  run_simple 'git config user.email cucumber@`hostname --fqdn`'
  cd '../working-repository'
  run_simple 'git remote add origin ../remote-repository'
end

Given(/^a repository cloned from "(.*)"$/) do |fixture|
  repo_path = File.join(ENV['FIXTURES_DIR'], 'git', fixture)
  run_simple "git clone --mirror \"#{repo_path}\" remote-repository"
  run_simple "git clone remote-repository working-repository"
  cd 'working-repository'
  configure_git
end

When(/^remote repository is updated from "(.*)"$/) do |fixture|
  cd '../remote-repository'
  repo_path = File.join(ENV['FIXTURES_DIR'], 'git', fixture)
  run_simple "git fetch \"#{repo_path}\" 'refs/*:refs/*'"
  cd '../working-repository'
end

When /^I set the fake mode variable$/ do
  Dir.chdir(current_dir) do
    MiniGit::Capturing.git :config, 'vendorificator.stub', 'true'
  end
end

When /(?:I have following Gemfile|I change Gemfile to|following Gemfile):$/ do |gemfile_contents|
  write_file('Gemfile', gemfile_contents)
  run_simple(without_bundler('bundle'))
  run_simple 'git add Gemfile Gemfile.lock'
  run_simple 'git commit -m bundle'
end

When /^I change Vendorfile to:$/ do |vendorfile_contents|
  write_file('Vendorfile', vendorfile_contents)
  run_simple 'git commit -m "Updated Vendorfile" Vendorfile'
end

When /^I run vendor command "(.*)"$/ do |args|
  args = args.split
  args[0] = args[0].to_sym

  Dir.chdir(current_dir) do
    with_redirected_stdout do
      Vendorificator::CLI.start args
    end
  end
end

Before do
  @last_vendor_exception = nil
end

When /^I try to run vendor command "(.*)"$/ do |args|
  begin
    step "I run vendor command \"#{args}\""
  rescue => exc
    @last_vendor_exception = exc
  end
end

Then 'it fails' do
  assert { !!@last_vendor_exception }
end
