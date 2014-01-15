Feature: Fake mode for development.

Scenario: Conjuring a simple module in fake mode works.
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
    end
    """
  When I set the fake mode variable
  And I run vendor command "install -v 1"
  Then a file named "README" should exist
  And tag "vendor/generated/0.23" does not exist
  And branch "vendor/generated" does not exist

