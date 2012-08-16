Given /^nothing in particular$/ do
  nil # NOP
end

When /^nothing happens$/ do
  nil # NOP
end

Then /^the README file exists$/ do
  File.exists?('README').should be_true
end
