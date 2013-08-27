Feature: Environment management.

Scenario: Pushing to remote repo
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
    end
    """
  And a remote repository
  When I run vendor command "sync"
  And I run vendor command "push"
  Then branch "vendor/generated" exists in the remote repo
  And tag "vendor/generated/0.23" exists in the remote repo
  And notes ref "vendor" exists in the remote repo
  And there's a git commit note including "master" in "current_branch"

Scenario: Getting module information
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
    end
    """
  And a remote repository
  When I run vendor command "sync"
  And I run vendor command "info generated"
  Then the last vendor output should match /Module merged version: 0.23/
  And the last vendor output should match /unparsed_args/

Scenario: Getting revision information
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
    end
    """
  And a remote repository
  When I run vendor command "sync"
  And I run vendor command "info HEAD^2"
  Then the last vendor output should match /master, vendor\/generated/
  Then the last vendor output should match /:unparsed_args/

Scenario: Working with empty Vendorfile
  Given a repository with following Vendorfile:
    """ruby
    """
  And a remote repository
  When I run vendor command "sync"
  And I run vendor command "status"
  Then the last vendor output should match /\A\z/

Scenario: Running tasks without Vendorfile where they don't need it
  Given a directory named "foo"
  When I cd to "foo"
  And I run vendor command "help"
  Then the last vendor output should match /Show differences between work tree/
  And the last vendor output should not match /Vendorfile not found/

Scenario: Running tasks without Vendorfile where they need it
  Given a directory named "foo"
  When I cd to "foo"
  And I run vendor command "pull"
  Then the last vendor output should match /Vendorfile not found/
