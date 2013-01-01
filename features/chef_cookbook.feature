Feature: Chef cookbooks from Opscode Community website

Scenario: A single cookbook, without dependencies

Scenario: Version & checksum
  Given a repository with following Vendorfile:
    """
    require 'vendorificator/vendor/chef_cookbook'

    chef_cookbook 'apt'
    """
  When I run "vendorify"
  Then I'm on "master" branch
  And branch "vendor/cookbooks/apt" exists
  And tag matching "^vendor/cookbooks/apt/" exists
  And file "vendor/cookbooks/apt/metadata.rb" exists

Scenario: Dependency hook
  Given a repository with following Vendorfile:
    """
    require 'vendorificator/vendor/chef_cookbook'

    chef_cookbook 'memcached'
    """
  When I run "vendorify"
  Then I'm on "master" branch
  And branch "vendor/cookbooks/memcached" exists
  And tag matching "^vendor/cookbooks/memcached/" exists
  And file "vendor/cookbooks/memcached/metadata.rb" exists
  And branch "vendor/cookbooks/runit" exists
  And tag matching "^vendor/cookbooks/runit/" exists
  And file "vendor/cookbooks/runit/metadata.rb" exists

@wip
Scenario: Ignored dependency
  Given a repository with following Vendorfile:
    """
    require 'vendorificator/vendor/chef_cookbook'

    chef_cookbook_ignore_dependencies ['runit']

    chef_cookbook 'memcached'
    """
  When I run "vendorify"
  Then I'm on "master" branch
  And branch "vendor/cookbooks/memcached" exists
  And tag matching "^vendor/cookbooks/memcached/" exists
  And file "vendor/cookbooks/memcached/metadata.rb" exists
  And branch "vendor/cookbooks/runit" does not exist
  And tag matching "^vendor/cookbooks/runit/" does not exist
  And file "vendor/cookbooks/runit/metadata.rb" does not exist
