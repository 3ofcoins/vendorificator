Given /^nothing in particular$/ do
  nil # NOP
end

When /^nothing happens$/ do
  nil # NOP
end

Then /^file "(.*?)" exists$/ do |path|
  assert { File.exists?(path) }
end

Then /^file "(.*?)" does not exist$/ do |path|
  deny { File.exists?(path) }
end

Then /^the README file exists$/ do
  step 'file "README" exists'
end

Then /^file "(.*?)" reads "(.*?)"$/ do |path, text|
  assert { File.read(path).strip == text.strip }
end

Given /^a repository with following Vendorfile:$/ do |string|
  commit_file('Vendorfile', string)
end

When /^I try to run "(.*?)"$/ do |command_string|
  run command_string
end

When /^I run "(.*?)"$/ do |command|
  step "I try to run \"#{command}\""
  assert { command_succeeded }
end

Then /the command has failed/ do
  deny { command_succeeded }
end

Then /^command (output|stdout|stderr) includes (#{PATTERN})$/ do |stream, pat|
  assert { command_output(stream) =~ pat }
end

Then /^command (output|stdout|stderr) does not include (#{PATTERN})$/ do |stream, pat|
  deny { command_output(stream) =~ pat }
end
