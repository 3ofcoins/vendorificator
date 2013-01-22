Feature: Module status

The `status` subcommand statuss all known modules and their status.

Background:
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """

Scenario: status new module
  When I run "vendor status"
  Then command output includes /new\s+generated\/0.23/

Scenario: status up-to-date module
  When I run "vendor"
  And I run "vendor status"
  Then command output includes /up to date\s+generated\/0.23/

Scenario: status outdated modules
  When I run "vendor"
  And I change Vendorfile to:
    """ruby
    vendor 'generated', :version => '0.42' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, Updated, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """
  And I run "vendor status"
  Then command output includes /outdated\s+generated\/0.42/

Scenario: Module's dependencies are statused if they are known
  When I change Vendorfile to:
    """ruby
    require 'vendorificator/vendor/chef_cookbook'
    chef_cookbook 'memcached'
    """
  And I run "vendor status"
  Then command output includes /new\s+memcached/
  And command output does not include "runit"
  When I run "vendor"
  And I run "vendor status"
  Then command output includes /up to date\s+memcached/
  And command output includes /up to date\s+runit/
