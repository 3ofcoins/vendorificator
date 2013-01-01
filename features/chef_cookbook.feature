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
