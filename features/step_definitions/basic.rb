Given /^nothing in particular$/ do
  nil # NOP
end

When /^nothing happens$/ do
  nil # NOP
end


Then /^file "(.*?)" exists$/ do |path|
  File.exists?(path).should be_true
end

Then /^the README file exists$/ do
  step 'file "README" exists'
end

Given /^a repository with following Vendorfile:$/ do |string|
  File.open("Vendorfile", "w") { |f| f.puts(string) }
  @git.add("Vendorfile")
  @git.commit("Added Vendorfile")
end

When /^I run "(.*?)"$/ do |command|
  @command = Mixlib::ShellOut.new(command)
  @command.run_command.error!
end
