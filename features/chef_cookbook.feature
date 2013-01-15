Feature: Chef cookbooks from Opscode Community website

Scenario: A single cookbook, without dependencies

Scenario: Version & checksum
  Given a repository with following Vendorfile:
    """
    require 'vendorificator/vendor/chef_cookbook'

    chef_cookbook 'apt'
    """
  When I run "vendorify"
  Then following has been conjured:
    | Name      | cookbooks/apt |
    | With file | metadata.rb   |

Scenario: Dependency hook
  Given a repository with following Vendorfile:
    """
    require 'vendorificator/vendor/chef_cookbook'

    chef_cookbook 'memcached'
    """
  When I run "vendorify"
  Then following has been conjured:
    | Name      | cookbooks/memcached | cookbooks/runit |
    | With file | metadata.rb         | metadata.rb     |

Scenario: Ignored dependency
  Given a repository with following Vendorfile:
    """
    require 'vendorificator/vendor/chef_cookbook'

    chef_cookbook_ignore_dependencies ['runit']

    chef_cookbook 'memcached'
    """
  When I run "vendorify"
  Then following has been conjured:
    | Name      | cookbooks/memcached |
    | With file | metadata.rb         |
  And following has not been conjured:
    | Name      | cookbooks/runit |
    | With file | metadata.rb     |
