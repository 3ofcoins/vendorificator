Feature: Environment management.

Scenario: Pushing to remote repo
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
    end
    """
  And a remote repository
  When I run vendor command "install"
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
  When I run vendor command "install"
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
  When I run vendor command "install"
  And I run vendor command "info HEAD^2"
  Then the last vendor output should match /master, vendor\/generated/
  Then the last vendor output should match /:unparsed_args/
