Feature: deprecation warnings

Background:
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
    end
    """

Scenario: `vendorify` command prints a deprecation warning
  When I successfully run `vendorify`
  Then the output should contain "DEPRECATED"

Scenario: `vendor` command doesn't print a deprecation warning
  When I successfully run `vendor`
  Then the output should not contain "DEPRECATED"
