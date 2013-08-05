Feature: Environment management.

Background:
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """
  And a remote repository

Scenario: Pushing to remote repo
  When I run vendor command "install"
  And I run vendor command "push"
  Then branch "vendor/generated" exists in the remote repo
  And tag "vendor/generated/0.23" exists in the remote repo
  And notes ref "vendor" exists in the remote repo
  And there's a git commit note including "master" in "current_branch"

Scenario: Getting module information
  When I run vendor command "install"
  And I run vendor command "info generated"
  Then the last vendor output should match /Module merged version: 0.23/
  And the last vendor output should match /unparsed_args/

Scenario: Getting revision information
  When I run vendor command "install"
  And I run vendor command "info HEAD^2"
  Then the last vendor output should match /master, vendor\/generated/
  Then the last vendor output should match /:unparsed_args/

Scenario: Getting module list
  When I run vendor command "install"
  And I run vendor command "list"
  Then the last vendor output should match /Module: generated, version: 0.23/

Scenario: Getting list of outdated modules
  When I run vendor command "install"
  And I change Vendorfile to:
    """ruby
    vendor 'generated', :version => '0.42' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, Updated, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """
  And I run vendor command "outdated"
  Then the last vendor output should match /outdated\s+generated/
