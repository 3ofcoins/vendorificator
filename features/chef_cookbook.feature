Feature: Chef cookbooks from Opscode Community website

Scenario: A single cookbook, without dependencies
  Given a repository with following Vendorfile:
    """ruby
    chef_cookbook 'apt'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | cookbooks/apt        |
    | With file | metadata.rb          |

Scenario: Dependency hook
  Given a repository with following Vendorfile:
    """ruby
    chef_cookbook 'memcached'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | cookbooks/memcached | cookbooks/runit |
    | With file | metadata.rb         | metadata.rb     |

Scenario: Ignored dependency
  Given a repository with following Vendorfile:
    """ruby
    chef_cookbook_ignore_dependencies ['runit']
    chef_cookbook 'memcached'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | cookbooks/memcached        |
    | With file | metadata.rb                |
  And following has not been conjured:
    | Name      | cookbooks/runit |
    | With file | metadata.rb     |

Scenario: Ignored all dependencies
  Given a repository with following Vendorfile:
    """ruby
    chef_cookbook_ignore_dependencies true
    chef_cookbook 'chef-server'
    """
  When I run vendor command "install"
  Then following has been conjured:
    | Name      | cookbooks/chef-server |
    | With file | metadata.rb           |
  And following has not been conjured:
    | Name      | cookbooks/runit |
    | With file | metadata.rb     |
  And following has not been conjured:
    | Name      | cookbooks/daemontools |
    | With file | metadata.rb           |
  And following has not been conjured:
    | Name      | cookbooks/apache2 |
    | With file | metadata.rb       |
