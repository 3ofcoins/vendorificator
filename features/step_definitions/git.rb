Then /^git repository is clean$/ do
  assert { repo_clean? }
end

Then /^git history has one commit$/ do
  assert { git.log.count == 1 }
end

Then /^I\'m on "(.*?)" branch$/ do |expected_branch|
  assert { branch == expected_branch }
end

Then /^no other branch exists$/ do
  assert { branches.length == 1 }
end

Then /^branch "(.*?)" exists$/ do |branch_name|
  assert { branches.include?(branch_name) }
end

Then /^branch "(.*?)" does not exist$/ do |branch_name|
  deny { branches.include?(branch_name) }
end

Then /^tag "(.*?)" exists$/ do |tag_name|
  assert { tags.include?(tag_name) }
end

Then /^tag "(.*?)" does not exist$/ do |tag_name|
  deny { tags.include?(tag_name) }
end

Then /^tag matching (#{PATTERN}) exists$/ do |pat|
  assert { tags.any?{|t| t=~pat} }
end

Then /^tag matching (#{PATTERN}) does not exist$/ do |pat|
  deny { tags.any?{|t| t=~pat} }
end
