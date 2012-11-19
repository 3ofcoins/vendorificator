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
  @git.branches.map(&:to_s).include?(branch_name).should be_true
end

Then /^tag "(.*?)" exists$/ do |branch_name|
  @git.tags.map(&:name).include?(branch_name).should be_true
end
