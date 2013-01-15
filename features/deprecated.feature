Feature: deprecation warnings

Background:
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
    end
    """

Scenario: `vendorify` command prints a deprecation warning
  When I run "vendorify"
  Then command output includes "DEPRECATED: `vendorify` command is deprecated, run `vendor` instead"

Scenario: `vendor` command doesn't print a deprecation warning
  When I run "vendor"
  Then command output does not include "DEPRECATED: `vendorify` command is deprecated, run `vendor` instead"
