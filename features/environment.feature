Feature: Environment management.

Scenario:
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
  And note "vendor" exists in the remote repo
