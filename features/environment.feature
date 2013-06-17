Feature: Environment management.

Scenario: Pushing to remote repo
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
    end
    """
  And a remote repository
  When I successfully run `vendor sync`
  And I successfully run `vendor push`
  Then branch "vendor/generated" exists in the remote repo
  And tag "vendor/generated/0.23" exists in the remote repo
  And notes ref "vendor" exists in the remote repo

Scenario: Getting module information
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
    end
    """
  And a remote repository
  When I successfully run `vendor sync`
  And I successfully run `vendor info generated`
  Then the last output should match /Module merged version: 0.23/
  And the last output should match /unparsed_args/

Scenario: Getting revision information
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
    end
    """
  And a remote repository
  When I successfully run `vendor sync`
  And I successfully run `vendor info HEAD\^2`
  Then the last output should match /master, vendor\/generated/
