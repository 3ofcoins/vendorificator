Given /^nothing in particular$/ do
  nil # NOP
end

When /^nothing happens$/ do
  nil # NOP
end

Then /^file "(.*?)" exists$/ do |path|
  File.exists?(path).should be_true
end

Then /^file "(.*?)" does not exist$/ do |path|
  File.exists?(path).should be_false
end

Then /^the README file exists$/ do
  step 'file "README" exists'
end

Then /^file "(.*?)" reads "(.*?)"$/ do |path, text|
  File.read(path).strip.should == text.strip
end

Given /^a repository with following Vendorfile:$/ do |string|
  File.open("Vendorfile", "w") { |f| f.puts(string) }
  @git.add("Vendorfile")
  @git.commit("Added Vendorfile")
end

When /^I try to run "(.*?)"$/ do |command|
  @command = Mixlib::ShellOut.new(command,
    :environment => {
      'GIT_DIR' => nil,
      'GIT_INDEX_FILE' => nil,
      'GIT_WORK_TREE' => nil })
  @command.run_command

  if ENV['VERBOSE']
    puts <<EOF
---- BEGIN #{command} ----
--- STATUS ---
#{@command.exitstatus}

--- STDOUT ---
#{@command.stdout}

--- STDERR ---
#{@command.stderr}

---- END ----
EOF
  end
end

When /^I run "(.*?)"$/ do |command|
  step "I try to run \"#{command}\""
  @command.error!
end

Then /the command has failed/ do
  expect { @command.error! }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
end
