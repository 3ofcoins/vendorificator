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
  assert { rescuing { @command.error! }.is_a?(
      Mixlib::ShellOut::ShellCommandFailed ) }
end

Then /^command output includes "(.*?)"$/ do |str|
  assert { @command.stdout.strip_console_escapes.include?(str) }
end

Then /^command output does not include "(.*?)"$/ do |str|
  deny { @command.stdout.strip_console_escapes.include?(str) }
end

Then /^command output matches "(.*?)"$/ do |re|
  assert { @command.stdout.strip_console_escapes =~ Regexp.new(re) }
end

Then /^command output does not match "(.*?)"$/ do |re|
  deny { @command.stdout.strip_console_escapes =~ Regexp.new(re) }
end
