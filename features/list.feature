Feature: listing the modules

The `list` subcommand lists all known modules and their status.

Background:
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """

Scenario: list new module
  When I run "vendor list"
  Then command output includes /NEW\s+generated 0.23/

Scenario: list up-to-date module
  When I run "vendor"
  And I run "vendor list"
  Then command output includes /UP TO DATE\s+generated 0.23/

Scenario: list outdated modules
  When I run "vendor"
  And I change Vendorfile to:
    """ruby
    vendor 'generated', :version => '0.42' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, Updated, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """
  And I run "vendor list"
  Then command output includes /OUTDATED\s+generated 0.42/

Scenario: Module's dependencies are listed if they are known
  When I change Vendorfile to:
    """ruby
    require 'vendorificator/vendor/chef_cookbook'
    chef_cookbook 'memcached'
    """
  And I run "vendor list"
  Then command output includes /NEW\s+memcached/
  And command output does not include "runit"
  When I run "vendor"
  And I run "vendor list"
  Then command output includes /UP TO DATE\s+memcached/
  And command output includes /UP TO DATE\s+runit/
