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
  write_file('README', 'Lorem ipsum dolor sit amet')
  write_file('Vendorfile', vendorfile_contents)
  run_simple 'git add .'
  run_simple 'git commit -m "New repo"'
end

When /^I change Vendorfile to:$/ do |vendorfile_contents|
  write_file('Vendorfile', vendorfile_contents)
  run_simple 'git commit -m "Updated Vendorfile" Vendorfile'
end
