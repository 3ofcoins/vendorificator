Then /^git repository is clean$/ do
  # FIXME: How to do that with ruby-git?
  `git status --porcelain`.should == ""
end

Then /^git history has one commit$/ do
  @git.log.count.should == 1
end

Then /^I\'m on "(.*?)" branch$/ do |expected_branch|
  @git.current_branch.should == expected_branch
end

Then /^no other branch exists$/ do
  @git.branches.to_a.length.should == 1
end

Then /^branch "(.*?)" exists$/ do |branch_name|
  @git.branches.map(&:to_s).should include branch_name
end

Then /^branch "(.*?)" does not exist$/ do |branch_name|
  @git.branches.map(&:to_s).should_not include branch_name
end

Then /^tag "(.*?)" exists$/ do |tag_name|
  @git.tags.map(&:name).should include tag_name
end

Then /^tag "(.*?)" does not exist$/ do |tag_name|
  @git.tags.map(&:name).should_not include tag_name
end

Then /^tag matching "(.*?)" exists$/ do |re|
  re = Regexp.new(re)
  @git.tags.map(&:name).should be_any { |b| re === b }
end
