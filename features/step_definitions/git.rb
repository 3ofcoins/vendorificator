Then /^git repository is clean$/ do
  assert { git.status(:porcelain => true) == '' }
end

Then /^git history has (\d+) commit(?:s)?$/ do |ncommits|
  assert { git.rev_list(:all => true).lines.count == ncommits.to_i }
end

Then /^I\'m on "(.*?)" branch$/ do |expected_branch|
  assert { git.rev_parse({:abbrev_ref => true}, 'HEAD').strip == expected_branch }
end

Then /^no other branch exists$/ do
  assert { git.branch.lines.count == 1 }
end

Then /^branch "(.*?)" exists$/ do |branch_name|
  assert { git.heads.include?(branch_name) }
end

Then /^branch "(.*?)" does not exist$/ do |branch_name|
  deny { git.heads.include?(branch_name) }
end

Then /^tag "(.*?)" exists$/ do |tag_name|
  assert { git.tags.include?(tag_name) }
end

Then /^tag "(.*?)" does not exist$/ do |tag_name|
  deny { git.tags.include?(tag_name) }
end

Then /^tag matching (#{PATTERN}) exists$/ do |pat|
  assert { git.tags.any? { |t| t =~ pat } }
end

Then /^tag matching (#{PATTERN}) does not exist$/ do |pat|
  deny { git.tags.any? { |t| t =~ pat } }
end

Then(/^there's a git log message including "(.*?)"$/) do |message|
  assert { git.log.lines.any? { |ln| ln.include?(message) } }
end

Then /^branch "(.*?)" exists in the remote repo$/ do |branch_name|
  assert { remote_git.heads.include?(branch_name) }
end

Then /^tag "(.*?)" exists in the remote repo$/ do |tag_name|
  assert { remote_git.tags.include?(tag_name) }
end
