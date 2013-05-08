Given /^nothing in particular$/ do
  nil # NOP
end

When /^nothing happens$/ do
  nil # NOP
end

Given /^a repository with following Vendorfile:$/ do |vendorfile_contents|
  create_dir 'working-repository'
  cd 'working-repository'
  run_simple 'git init'
  # Configure Git username & email to unclutter console output
  run_simple 'git config user.name Cucumber'
  run_simple 'git config user.email cucumber@`hostname --fqdn`'
  write_file('README', 'Lorem ipsum dolor sit amet')
  write_file('Vendorfile', vendorfile_contents)
  run_simple 'git add .'
  run_simple 'git commit -m "New repo"'
end

Given /^I have following Gemfile:$/ do |gemfile_contents|
  write_file('Gemfile', gemfile_contents)
  run_simple(without_bundler('bundle'))
  run_simple 'git add Gemfile Gemfile.lock'
  run_simple 'git commit -m bundle'
end

Given /^a remote repository$/ do
  create_dir '../remote-repository'
  cd '../remote-repository'
  run_simple 'git init --bare'
  # Configure Git username & email to unclutter console output
  run_simple 'git config user.name Cucumber'
  run_simple 'git config user.email cucumber@`hostname --fqdn`'
  cd '../working-repository'
  run_simple 'git remote add origin ../remote-repository'
end

When /^I change Vendorfile to:$/ do |vendorfile_contents|
  write_file('Vendorfile', vendorfile_contents)
  run_simple 'git commit -m "Updated Vendorfile" Vendorfile'
end
