
Then /^the last output should match (#{PATTERN})$/ do |expected|
  assert { last_output =~ expected }
end

Then /^the last output should not match (#{PATTERN})$/ do |expected|
  deny { last_output =~ expected }
end

Then /^it should fail$/ do
  deny { last_exit_status == 0 }
end
