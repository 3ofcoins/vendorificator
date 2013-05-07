Then /^the last output should match (#{PATTERN})$/ do |expected|
  assert { last_output =~ expected }
end

Then /^the last output should not match (#{PATTERN})$/ do |expected|
  deny { last_output =~ expected }
end

Then /^it should fail$/ do
  deny { last_exit_status == 0 }
end

Then /^I successfully run `(.*)` with bundler disabled/ do |command|
  unset_bundler_env_vars
  step "I successfully run `#{command}`"
end
