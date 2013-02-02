Feature: Git-based vendor module

Scenario:
  Given a repository with following Vendorfile:
    """ruby
    git "file://#{ENV['FIXTURES_DIR']}/git/testrepo"
    """
  When I run "vendor sync"
  Then following has been conjured:
    | Name      | testrepo                                 |
    | Version   | 10e9ac58c77bc229d8c59a5b4eb7422916453148 |
    | With file | test/alias.c                             |
