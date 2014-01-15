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

Then /^there's a git log message including "(.*?)"$/ do |message|
  assert { git.log.lines.any? { |ln| ln.include?(message) } }
end

Then /^there's a git commit note including "(.*?)" in "(.*?)"$/ do |value, key|
  # Not in the assert block, because it raises an exception on failure.
  contains_note = git.notes({:ref => 'vendor'}, 'list').lines.any? do |line|
    note = YAML.load git.show(line.split[0])
    (note[key] || note[key.to_sym]).to_s.include? value
  end
  assert { contains_note == true }
end

Then /^branch "(.*?)" exists in the remote repo$/ do |branch_name|
  assert { remote_git.heads.include?(branch_name) }
end

Then /^tag "(.*?)" exists in the remote repo$/ do |tag_name|
  assert { remote_git.tags.include?(tag_name) }
end

Then /^notes ref "(.*?)" exists in the remote repo$/ do |ref_name|
  assert { remote_git.note_refs.include?(ref_name) }
end

def branch_contains?(branch, path)
  @branch_files ||= {}
  @branch_files[branch] ||= git.capturing.
    ls_tree( {:r => true, :z => true, :name_only => true}, branch).
    split("\0")
  @branch_files[branch].include?(path)
end

Then(/^the branch "(.*?)" should contain file "(.*?)"$/) do |branch, path|
  assert { branch_contains?(branch, path) }
end

Then(/^the branch "(.*?)" should not contain file "(.*?)"$/) do |branch, path|
  deny { branch_contains?(branch, path) }
end
