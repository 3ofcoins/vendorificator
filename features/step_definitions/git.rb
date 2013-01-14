Then /^git repository is clean$/ do
  # FIXME: How to do that with ruby-git?
  assert { `git status --porcelain` == "" }
end

Then /^git history has one commit$/ do
  assert { @git.log.count == 1 }
end

Then /^I\'m on "(.*?)" branch$/ do |expected_branch|
  assert { @git.current_branch == expected_branch }
end

Then /^no other branch exists$/ do
  assert { @git.branches.to_a.length == 1 }
end

Then /^branch "(.*?)" exists$/ do |branch_name|
  assert { @git.branches.map(&:to_s).include?(branch_name) }
end

Then /^branch "(.*?)" does not exist$/ do |branch_name|
  deny { @git.branches.map(&:to_s).include?(branch_name) }
end

Then /^tag "(.*?)" exists$/ do |tag_name|
  assert { @git.tags.map(&:name).include?(tag_name) }
end

Then /^tag "(.*?)" does not exist$/ do |tag_name|
  deny { @git.tags.map(&:name).include?(tag_name) }
end

Then /^tag matching "(.*?)" exists$/ do |re|
  re = Regexp.new(re)
  assert { @git.tags.map(&:name).any? { |b| b =~ re } }
end

Then /^tag matching "(.*?)" does not exist$/ do |re|
  re = Regexp.new(re)
  deny { @git.tags.map(&:name).any? { |b| b =~ re } }
end
